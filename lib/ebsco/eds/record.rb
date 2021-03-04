require 'yaml'
require 'json'
require 'cgi'

module EBSCO

  module EDS

    # A single search result
    class Record

      ATTRIBUTES = [
          :id,
          :eds_accession_number,
          :eds_database_id,
          :eds_database_name,
          :eds_access_level,
          :eds_relevancy_score,
          :eds_title,
          :eds_source_title,
          :eds_composed_title,
          :eds_other_titles,
          :eds_abstract,
          :eds_authors,
          :eds_author_affiliations,
          :eds_authors_composed,
          :eds_subjects,
          :eds_subjects_geographic,
          :eds_subjects_person,
          :eds_subjects_company,
          :eds_subjects_mesh,
          :eds_subjects_bisac,
          :eds_subjects_genre,
          :eds_author_supplied_keywords,
          :eds_descriptors,
          :eds_notes,
          :eds_subset,
          :eds_languages,
          :eds_page_count,
          :eds_page_start,
          :eds_physical_description,
          :eds_publication_type,
          :eds_publication_type_id,
          :eds_publication_date,
          :eds_publication_year,
          :eds_publication_info,
          :eds_publication_status,
          :eds_publisher,
          :eds_document_type,
          :eds_document_doi,
          :eds_document_oclc,
          :eds_issn_print,
          :eds_issns,
          :eds_isbn_print,
          :eds_isbn_electronic,
          :eds_isbns_related,
          :eds_isbns,
          :eds_series,
          :eds_volume,
          :eds_issue,
          :eds_covers,
          :eds_cover_thumb_url,
          :eds_cover_medium_url,
          :eds_fulltext_word_count,
          :eds_result_id,
          :eds_plink,
          :eds_ebook_pdf_fulltext_available,
          :eds_ebook_epub_fulltext_available,
          :eds_pdf_fulltext_available,
          :eds_html_fulltext_available,
          :eds_html_fulltext,
          :eds_images,
          :eds_quick_view_images,
          :eds_all_links,
          :eds_fulltext_links,
          :eds_non_fulltext_links,
          :eds_code_naics,
          :eds_abstract_supplied_copyright,
          # publication record attributes
          :eds_publication_id,
          :eds_publication_is_searchable,
          :eds_publication_scope_note,
          :eds_citation_exports,
          :eds_citation_styles
      ]

      KNOWN_ITEM_NAMES = %w(
          URL
          Title
          TitleSource
          TitleAlt
          Abstract
          Note
          Author
          AffiliationAuthor
          Subject
          SubjectGeographic
          SubjectPerson
          SubjectCompany
          SubjectMESH
          SubjectBISAC
          SubjectGenre
          Subset
          Language
          PhysDesc
          TypePub
          DatePub
          TypeDocument
          DOI
          ISSN
          SeriesInfo
          FullTextWordCount
          AbstractSuppliedCopyright
          CodeNAICS
          NoteScope
          Publisher
        )

      KNOWN_ITEM_LABELS = [
          'OCLC',
          'Descriptors',
          'Publication Information',
          'Related ISBNs'
      ]

      # Raw record as returned by the \EDS API via search or retrieve
      attr_accessor(*ATTRIBUTES)

      def attributes
        ATTRIBUTES.map{|attribute| self.send(attribute) }
      end

      # Creates a search or retrieval result record
      def initialize(results_record, eds_config = nil)

        # translate all subject search link field codes to DE?
        @all_subjects_search_links = false
        if eds_config
          @all_subjects_search_links = eds_config[:all_subjects_search_links]
        end
        if ENV.has_key? 'EDS_ALL_SUBJECTS_SEARCH_LINKS'
          @all_subjects_search_links = ENV['EDS_ALL_SUBJECTS_SEARCH_LINKS']
        end

        # decode and sanitize html in item data?
        @decode_sanitize_html = false
        if eds_config
          @decode_sanitize_html = eds_config[:decode_sanitize_html]
        end
        if ENV.has_key? 'EDS_DECODE_SANITIZE_HTML'
          @decode_sanitize_html = ENV['EDS_DECODE_SANITIZE_HTML']
        end

        require_sanitize if @decode_sanitize_html


        if results_record.key? 'Record'
          @record = results_record['Record'] # single record returned by retrieve api
        else
          @record = results_record # set of records returned by search api
        end

        @items = @record.fetch('Items', {})

        @bib_entity = @record.fetch('RecordInfo', {}).fetch('BibRecord', {}).fetch('BibEntity', {})

        @bib_relationships = @record.fetch('RecordInfo', {}).fetch('BibRecord', {}).fetch('BibRelationships', {})

        @bib_part = @record.fetch('RecordInfo', {})
                        .fetch('BibRecord', {})
                        .fetch('BibRelationships', {})
                        .fetch('IsPartOfRelationships', {})[0]

        @image_quick_view_items = @record.fetch('ImageQuickViewItems', {})

        # accessors:
        @eds_result_id = @record['ResultId']
        @eds_plink = @record['PLink']
        @eds_accession_number = @record['Header']['An'].to_s
        @eds_database_id = @record['Header']['DbId'].to_s
        @eds_database_name = @record['Header']['DbLabel']
        @eds_access_level = @record['Header']['AccessLevel']
        @eds_relevancy_score =  @record['Header']['RelevancyScore']
        @id = @eds_database_id + '__' + @eds_accession_number
        @eds_title = title
        @eds_source_title = source_title
        @eds_composed_title = get_item_data({name: 'TitleSource'})
        @eds_other_titles = get_item_data({name: 'TitleAlt'})
        @eds_abstract = get_item_data({name: 'Abstract'})
        @eds_authors = bib_authors_list
        @eds_authors_composed = get_item_data({name: 'Author'})
        @eds_author_affiliations = get_item_data({name: 'AffiliationAuthor'})
        @eds_subjects =
            get_item_data({name: 'Subject', label: 'Subject Terms', group: 'Su'}) ||
            get_item_data({name: 'Subject', label: 'Subject Indexing', group: 'Su'}) ||
            get_item_data({name: 'Subject', label: 'Subject Category', group: 'Su'}) ||
            get_item_data({name: 'Subject', label: 'KeyWords Plus', group: 'Su'}) ||
            bib_subjects
        @eds_subjects_geographic =
            get_item_data({name: 'SubjectGeographic', label: 'Geographic Terms', group: 'Su'}) ||
            get_item_data({name: 'Subject', label: 'Subject Geographic', group: 'Su'})
        @eds_subjects_person = get_item_data({name: 'SubjectPerson'})
        @eds_subjects_company = get_item_data({name: 'SubjectCompany'})
        @eds_subjects_bisac = get_item_data({name: 'SubjectBISAC'})
        @eds_subjects_mesh = get_item_data({name: 'SubjectMESH'})
        @eds_subjects_genre = get_item_data({name: 'SubjectGenre'})
        @eds_author_supplied_keywords = get_item_data({name: 'Keyword'})
        @eds_notes = get_item_data({name: 'Note'})
        @eds_subset = get_item_data({name: 'Subset'})
        @eds_languages = get_item_data({name: 'Language'}) || bib_languages
        @eds_page_count = bib_page_count
        @eds_page_start = bib_page_start
        @eds_physical_description = get_item_data({name: 'PhysDesc'})
        @eds_publication_type = @record['Header']['PubType'] || get_item_data({name: 'TypePub'})
        @eds_publication_type_id = @record['Header']['PubTypeId']
        @eds_publication_date = bib_publication_date || get_item_data({name: 'DatePub'})
        @eds_publication_year = bib_publication_year || get_item_data({name: 'DatePub'})
        @eds_publication_info = get_item_data({label: 'Publication Information'})
        @eds_publication_status = get_item_data({label: 'Publication Status'})
        @eds_publisher = get_item_data({name: 'Publisher'})
        @eds_document_type = get_item_data({name: 'TypeDocument'})
        @eds_document_doi = get_item_data({name: 'DOI'}) || bib_doi
        @eds_document_oclc = get_item_data({label: 'OCLC'})
        @eds_issn_print = get_item_data({name: 'ISSN'}) || bib_issn_print
        @eds_issns = bib_issns
        @eds_isbn_print = bib_isbn_print
        @eds_isbns_related = item_related_isbns
        @eds_isbn_electronic = bib_isbn_electronic
        @eds_isbns = bib_isbns || item_related_isbns
        @eds_series =  get_item_data({name: 'SeriesInfo'})
        @eds_volume = bib_volume
        @eds_issue = bib_issue
        @eds_covers = images
        @eds_cover_thumb_url = cover_thumb_url
        @eds_cover_medium_url = cover_medium_url
        @eds_fulltext_word_count = get_item_data({name: 'FullTextWordCount'}).to_i
        @eds_html_fulltext_available = html_fulltext_available
        @eds_html_fulltext = html_fulltext
        @eds_images = images
        @eds_quick_view_images = quick_view_images
        @eds_all_links = all_links
        # init fulltext available props, reset by fulltext_links method later
        @eds_pdf_fulltext_available = false
        @eds_ebook_pdf_fulltext_available = false
        @eds_ebook_epub_fulltext_available = false
        @eds_fulltext_links = fulltext_links
        @eds_non_fulltext_links = non_fulltext_links
        @eds_code_naics = get_item_data({name: 'CodeNAICS'})
        @eds_abstract_supplied_copyright = get_item_data({name: 'AbstractSuppliedCopyright'})
        @eds_descriptors = get_item_data({label: 'Descriptors'})
        @eds_publication_id = @record['Header']['PublicationId']
        @eds_publication_is_searchable = @record['Header']['IsSearchable']
        @eds_publication_scope_note = get_item_data({name: 'NoteScope'})

        # add item metadata
        @items.each do |item|
          unless KNOWN_ITEM_NAMES.include?(item['Name']) || KNOWN_ITEM_LABELS.include?(item['Label'])
            add_extra_item_accessors(item)
          end
        end

      end

      # --
      # ====================================================================================
      # MISC HELPERS
      # ====================================================================================
      # ++

      # \Options hash containing accession number and database ID. This can be passed to the retrieve method.
      def retrieve_options
        options = {}
        options['an'] = @eds_accession_number
        options['dbid'] = @eds_database_id
        options
      end

      # The title.
      def title
        _retval = bib_title || get_item_data({name: 'Title'})
        # TODO: make this configurable
        if _retval.nil?
          _retval = 'This title is unavailable for guests, please login to see more information.'
        end
        _retval
      end

      # The source title (example: 'Salem Press Encyclopedia')
      def source_title
        _retval = bib_source_title || get_item_data({name: 'TitleSource'})
        _reval = nil? if _retval == title # suppress if it's identical to title
        _retval.nil?? nil : _retval
      end

      # Cover image - thumbnail size link
      def cover_thumb_url
        if images('thumb').any?
          images('thumb').first[:src]
        else
          nil
        end
      end

      # Cover image - medium size link
      def cover_medium_url
        if images('medium').any?
          images('medium').first[:src]
        else
          nil
        end
      end

      # Fulltext available
      def html_fulltext_available
        if @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',0) == '1'
          true
        else
          false
        end
      end

      # Fulltext - RETRIEVE ONLY
      def html_fulltext
        if @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',0) == '1'

          # sanitize?
          if @decode_sanitize_html

            # transformer
            clean_fulltext = lambda do |env|
              node = env[:node]
              if node.name == 'title'
                node.name = 'h1'
              end
              if node.name == 'sbt'
                node.name = 'h2'
              end
              if node.name == 'jsection'
                node.name = 'h3'
              end
              if node.name == 'et'
                node.name = 'h3'
              end
              node
            end

            fulltext_config = Sanitize::Config.merge(Sanitize::Config::RELAXED,
                                                     :elements => Sanitize::Config::RELAXED[:elements] +
                                                        %w[relatesto searchlink],
                                                    :attributes => Sanitize::Config::RELAXED[:attributes].merge(
                                                        'searchlink' => %w[fieldcode term]),
            :remove_contents => true,
            :transformers => [clean_fulltext])

            html_decode_and_sanitize(@record.fetch('FullText',{}).fetch('Text',{})['Value'], fulltext_config)
          else
            @record.fetch('FullText',{}).fetch('Text',{})['Value']
          end
        else
          nil
        end
      end

      # List of cover images.
      def images (size_requested = 'all')
        returned_images = []
        images = @record.fetch('ImageInfo', {})
        if images.count > 0
          images.each do |image|
            if size_requested == image['Size'] || size_requested == 'all'
              returned_images.push({size: image['Size'], src: image['Target']})
            end
          end
        end
        returned_images
      end

      # List of image quick view
      def quick_view_images
        returned_images = []
        images = @record.fetch('ImageQuickViewItems', {})
        if images.count > 0
          images.each do |quick_view_item|
            image_id = quick_view_item['DbId']
            image_accession = quick_view_item['An']
            image_type = quick_view_item['Type']
            # todo: change to https, large/small url?
            image_url = quick_view_item['Url']
            returned_images.push({url: image_url, id: image_id, accession_number: image_accession, type: image_type})
          end
        end
        returned_images
      end

      # related ISBNs
      def item_related_isbns
        isbns = get_item_data({label: 'Related ISBNs'})
        if isbns
          isbns.split(' ').map!{|item| item.gsub(/\.$/, '')}
        else
          nil
        end
      end

      # --
      # ====================================================================================
      # LINK HELPERS
      # ====================================================================================
      # ++

      # A list of all available links.
      def all_links
        fulltext_links + non_fulltext_links
      end

      # The first fulltext link.
      def fulltext_link(type = 'first')
        fulltext_links.each do |link|
          if link[:type] == type
            return link
          end
        end
        fulltext_links.first || {}
      end

      # add protocol if needed
      def add_protocol(url)
        unless url[/\Ahttp:\/\//] || url[/\Ahttps:\/\//]
          url = "https://#{url}"
        end
        url
      end

      # All available fulltext links.
      def fulltext_links

        links = []

        ebscolinks = @record.fetch('FullText',{}).fetch('Links',{})
        if ebscolinks.count > 0
          ebscolinks.each do |ebscolink|
            if ebscolink['Type'] == 'pdflink'
              link_label = 'PDF Full Text'
              link_icon = 'PDF Full Text Icon'
              link_url = ebscolink['Url'] || 'detail'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'pdf', expires: true})
              @eds_pdf_fulltext_available = true
            end
          end
        end

        # commenting out for now, not sure how 'detail' urls are useful in a blacklight context?
        # htmlfulltextcheck = @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',{})
        # if htmlfulltextcheck == '1'
        #   link_url = 'detail'
        #   link_label = 'Full Text in Browser'
        #   link_icon = 'Full Text in Browser Icon'
        #   links.push({url: link_url, label: link_label, icon: link_icon, type: 'html'})
        # end

        if ebscolinks.count > 0
          ebscolinks.each do |ebscolink|
            if ebscolink['Type'] == 'ebook-pdf'
              link_label = 'PDF eBook Full Text'
              link_icon = 'PDF eBook Full Text Icon'
              link_url = ebscolink['Url'] || 'detail'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'ebook-pdf', expires: true})
              @eds_ebook_pdf_fulltext_available = true
            end
          end
        end

        if ebscolinks.count > 0
          ebscolinks.each do |ebscolink|
            if ebscolink['Type'] == 'ebook-epub'
              link_label = 'ePub eBook Full Text'
              link_icon = 'ePub eBook Full Text Icon'
              link_url = ebscolink['Url'] || 'detail'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'ebook-epub', expires: true})
              @eds_ebook_epub_fulltext_available = true
            end
          end
        end

        items = @record.fetch('Items',{})
        if items.count > 0
          items.each do |item|
            if item['Group'] == 'URL'
              if item['Data'].include? 'linkTerm=&quot;'
                link_start = item['Data'].index('linkTerm=&quot;')+15
                link_url = item['Data'][link_start..-1]
                link_end = link_url.index('&quot;')-1
                link_url = link_url[0..link_end]
                if item['Label']
                  link_label = item['Label']
                else
                  link_label_start = item['Data'].index('link&gt;')+8
                  link_label = item['Data'][link_label_start..-1]
                  link_label = link_label.strip
                end
              else
                link_url = item['Data']
                link_label = item['Label']
              end
              link_icon = 'Catalog Link Icon'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'cataloglink', expires: false})
            end
          end
        end

        if ebscolinks.count > 0
          ebscolinks.each do |ebscolink|
            if ebscolink['Type'] == 'other'
              link_label = 'Linked Full Text'
              link_icon = 'Linked Full Text Icon'
              link_url = ebscolink['Url'] || 'detail'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'smartlinks', expires: false})
              @eds_pdf_fulltext_available = true
            end
          end
        end

        ft_customlinks = @record.fetch('FullText',{}).fetch('CustomLinks',{})
        if ft_customlinks.count > 0
          ft_customlinks.each do |ft_customlink|
            link_url = ft_customlink['Url']
            link_url = add_protocol(link_url)
            link_label = ft_customlink['Text']
            link_icon = ft_customlink['Icon']
            links.push({url: link_url, label: link_label, icon: link_icon, type: 'customlink-fulltext', expires: false})
          end
        end

        links
      end

      # All available non-fulltext links.
      def non_fulltext_links
        links = []
        other_customlinks = @record.fetch('CustomLinks',{})
        if other_customlinks.count > 0
          other_customlinks.each do |other_customlink|
            link_url = other_customlink['Url']
            link_url = add_protocol(link_url)
            link_label = other_customlink['Text']
            link_icon = other_customlink['Icon']
            links.push({url: link_url, label: link_label, icon: link_icon, type: 'customlink-other', expires: false})
          end
        end

        links
      end

      # ====================================================================================
      # BIB ENTITY
      # ====================================================================================

      def bib_title
        if @bib_entity && @bib_entity.fetch('Titles', {}).any?
          item_bib_title = @bib_entity.fetch('Titles', {}).find{|item| item['Type'] == 'main'}
          if item_bib_title
            item_bib_title['TitleFull']
          else
            nil
          end
        else
          nil
        end
      end

      def bib_authors
        if @bib_relationships
          @bib_relationships.deep_find('NameFull').join('; ')
        else
          nil
        end
      end

      def bib_authors_list
        if @bib_relationships
          @bib_relationships.deep_find('NameFull')
        else
          nil
        end
      end

      def bib_subjects
        if @bib_entity
          @bib_entity.deep_find('SubjectFull')
        else
          nil
        end
      end

      def bib_languages
        if @bib_entity && @bib_entity.fetch('Languages', {}).any?
          @bib_entity.fetch('Languages', {}).map{|lang| lang['Text']}
        else
          nil
        end
      end

      # def bib_pages
      #   @bib_entity.fetch('PhysicalDescription', {})['Pagination']
      # end

      def bib_page_count
        if @bib_entity
          @bib_entity.deep_find('PageCount').first
        else
          nil
        end
      end

      def bib_page_start
        if @bib_entity
          @bib_entity.deep_find('StartPage').first
        else
          nil
        end
      end

      def bib_doi
        if @bib_entity && @bib_entity.fetch('Identifiers',{}).any?
          item_doi = @bib_entity.fetch('Identifiers',{}).find{|item| item['Type'] == 'doi'}
          if item_doi
            item_doi['Value']
          else
            nil
          end
        else
          nil
        end
      end

      # ====================================================================================
      # BIB - IS PART OF (journal, book)
      # ====================================================================================

      def bib_source_title
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Titles',{}).any?
          item_title_full = @bib_part.fetch('BibEntity',{}).fetch('Titles',{}).find{|item| item['Type'] == 'main'}
          if item_title_full
            item_title_full['TitleFull']
          else
            nil
          end
        else
          nil
        end
      end

      def bib_issn_print
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).any?
          item_issn_p = @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'issn-print'}
          if item_issn_p
            item_issn_p['Value']
          else
            nil
          end
        else
          nil
        end
      end

      def bib_issn_electronic
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).any?
          item_issn_e = @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'issn-electronic'}
          if item_issn_e
            item_issn_e['Value']
          else
            nil
          end
        else
          nil
        end
      end

      def bib_issns
        issns = []
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).any?
          @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).each do |id|
            if id['Type'].include?('issn') && !id['Type'].include?('locals')
              issns.push(id['Value'])
            end
          end
        end
        issns
      end

      def bib_isbn_print
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).any?
          item_isbn_p = @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'isbn-print'}
          if item_isbn_p
            item_isbn_p['Value']
          else
            nil
          end
        else
          nil
        end
      end

      def bib_isbn_electronic
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).any?
          item_isbn_e = @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'isbn-electronic'}
          if item_isbn_e
            item_isbn_e['Value']
          else
            nil
          end
        else
          nil
        end
      end

      # todo: make this generic and take an optional parameter for type
      def bib_isbns
        isbns = []
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).any?
          @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).each do |id|
            if id['Type'].include?('isbn') && !id['Type'].include?('locals')
              isbns.push(id['Value'])
            end
          end
        end
        isbns
      end

      def bib_publication_date
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).any?
          _date = @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).find{|item| item['Type'] == 'published'}
          if _date
            if _date.has_key?('Y') && _date.has_key?('M') && _date.has_key?('D')
              _date['Y'] + '-' + _date['M'] + '-' + _date['D']
            else
              nil
            end
          else
            nil
          end
        else
          nil
        end
      end

      def bib_publication_year
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).any?
          _date = @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).find{|item| item['Type'] == 'published'}
          if _date
            _date.has_key?('Y') ? _date['Y'] : nil
          else
            nil
          end
        else
          nil
        end
      end

      def bib_publication_month
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).any?
          _date = @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).find{|item| item['Type'] == 'published'}
          if _date
            _date.has_key?('M') ? _date['M'] : nil
          else
            nil
          end
        else
          nil
        end
      end

      def bib_volume
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).any?
          item_volume = @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).find{|item| item['Type'] == 'volume'}
          if item_volume
            item_volume['Value']
          else
            nil
          end
        else
          nil
        end
      end

      def bib_issue
        if @bib_part && @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).any?
          item_issue = @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).find{|item| item['Type'] == 'issue'}
          if item_issue
            item_issue['Value']
          else
            nil
          end
        else
          nil
        end
      end

      def to_attr_hash
        hash = Hash.new
        instance_variables.each do |var|
          if var != :@record &&
              var != :@items &&
              var != :@bib_entity &&
              var != :@bib_part &&
              var != :@bib_relationships &&
              var != :@image_quick_view_items &&
              var != :@eds_citation_exports &&
              var != :@eds_citation_styles
            hash[var.to_s.sub(/^@/, '')] = instance_variable_get(var)
          end
        end

        if all_links
          hash['eds_fulltext_link'] = { 'id' => @eds_database_id + '__' + @eds_accession_number,
                                        'links' => all_links }
        end

        # add citation styles and exports
        unless @eds_citation_exports.nil?
          hash['eds_citation_exports'] = @eds_citation_exports.items
        end
        unless @eds_citation_styles.nil?
          hash['eds_citation_styles'] = @eds_citation_styles.items
        end

        hash
      end

      def to_solr
        item_hash = to_attr_hash
        {
            'responseHeader' => {
                'status' => 0
            },
            'response' => {
                'numFound' => 1,
                'start' => 0,
                'docs' => [item_hash]
            }
        }
      end

      # ====================================================================================
      # ITEM DATA HELPERS
      # ====================================================================================


      def get_item_data(options)

        if @items.empty?
          nil
        else

          if options[:name] and options[:label] and options[:group]

            @items.each do |item|
              if item['Name'] == options[:name] && item['Label'] == options[:label] && item['Group'] == options[:group]
                return sanitize_data(item)
              end
            end
            return nil

          elsif options[:name] and options[:label]

            @items.each do |item|
              if item['Name'] == options[:name] && item['Label'] == options[:label]
                return sanitize_data(item)
              end
            end
            return nil

          elsif options[:name] and options[:group]

            @items.each do |item|
              if item['Name'] == options[:name] && item['Group'] == options[:group]
                return sanitize_data(item)
              end
            end
            return nil

          elsif options[:label] and options[:group]

            @items.each do |item|
              if item['Label'] == options[:label] && item['Group'] == options[:group]
                return sanitize_data(item)
              end
            end
            return nil

          elsif options[:label]

            @items.each do |item|
              if item['Label'] == options[:label]
                return sanitize_data(item)
              end
            end
            return nil

          elsif options[:name]

            @items.each do |item|
              if item['Name'] == options[:name]
                return sanitize_data(item)
              end
            end
            return nil

          else
            nil
          end

        end
      end

      # decode & sanitize html tags found in item data; apply any special transformations
      def sanitize_data(item)

        if item['Data']
          data = item['Data']

          # group-specific transformations
          if item['Group']
            group = item['Group']
            if group == 'Su'
              data = add_subject_searchlinks(data)
              # translate searchLink field codes to DE?
              if @all_subjects_search_links
                data = data.gsub(/(searchLink fieldCode=&quot;)([A-Z]+)/, '\1DE')
              end
            end
          end

          # decode-sanitize?
          if @decode_sanitize_html
           data = html_decode_and_sanitize(data)
          end

          data

        else
          nil # no item data present
        end

      end

      # Decode any html elements and then run it through sanitize to preserve entities (eg: ampersand) and strip out
      # elements/attributes that aren't explicitly whitelisted.
      # The RELAXED config: https://github.com/rgrove/sanitize/blob/master/lib/sanitize/config/relaxed.rb
      def html_decode_and_sanitize(data, config = nil)
        default_config = Sanitize::Config.merge(Sanitize::Config::RELAXED,
                                                 :elements => Sanitize::Config::RELAXED[:elements] +
                                                     %w[relatesto searchlink ephtml],
                                                 :attributes => Sanitize::Config::RELAXED[:attributes].merge(
                                                     'searchlink' => %w[fieldcode term]))
        sanitize_config = config.nil? ? default_config : config

        html = CGI.unescapeHTML(data.to_s)
        # need to double-unescape data with an ephtml section
        if html =~ /<ephtml>/
          html = CGI.unescapeHTML(html)
          html = html.gsub(/\\"/, '"')
          html = html.gsub(/\\n /, '')
        end

        sanitized_html = Sanitize.fragment(html, sanitize_config)
        # sanitize 5.0 fails to restore element case after doing lowercase
        sanitized_html = sanitized_html.gsub(/<searchlink/, '<searchLink')
        sanitized_html = sanitized_html.gsub(/<\/searchlink>/, '</searchLink>')
        sanitized_html

      end

      # dynamically add item metadata as 'eds_extra_ItemNameOrLabel'
      def add_extra_item_accessors(item)
        key = item['Name'] ? item['Name'].gsub(/\s+/, '_') : item['Label'].gsub(/\s+/, '_')
        # NumberOther isn't always unique, concatenate the label
        if key == 'NumberOther' or key == 'Number_Other'
          key = 'number_other_' + item['Label'].gsub(/\s+/, '_')
        end
        value = item['Data']
        unless key.nil?
          key = "eds_extras_#{key}"
          unless value.nil?
            self.class.class_eval { attr_accessor key }
            self.instance_variable_set "@#{key}", CGI.unescapeHTML(value)
          end
        end
      end

      def set_citation_exports(val)
        @eds_citation_exports = val
      end

      def set_citation_styles(val)
        @eds_citation_styles = val
      end

      # add searchlinks when they don't exist
      def add_subject_searchlinks(data)
        subjects = data
        unless data.include? 'searchLink'
          subjects = subjects.split('&lt;br /&gt;').map do |su|
            '&lt;searchLink fieldCode=&quot;DE&quot; term=&quot;%22' + su + '%22&quot;&gt;' + su + '&lt;/searchLink&gt;'
          end.join('&lt;br /&gt;')
        end
        subjects
      end

      def require_sanitize
        require 'sanitize'
      rescue Gem::LoadError, LoadError
        raise EBSCO::EDS::MissingDependency.new 'Sanitize is turned on, but the sanitize gem is not loaded'
      end

    end # Class Record
  end # Module EDS
end # Module EBSCO


# monkey patches
class Hash
  def deep_find(key, object=self, found=[])
    if object.respond_to?(:key?) && object.key?(key)
      found << object[key]
    end
    if object.is_a? Enumerable
      found << object.collect { |*a| deep_find(key, a.last) }
    end
    found.flatten.compact
  end
end

