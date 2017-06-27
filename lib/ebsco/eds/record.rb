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
          :eds_other_titles,
          :eds_abstract,
          :eds_authors,
          :eds_author_affiliations,
          :eds_subjects,
          :eds_subjects_geographic,
          :eds_subjects_person,
          :eds_author_supplied_keywords,
          :eds_notes,
          :eds_languages,
          :eds_page_count,
          :eds_page_start,
          :eds_physical_description,
          :eds_publication_type,
          :eds_publication_type_id,
          :eds_publication_date,
          :eds_publication_year,
          :eds_publication_info,
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
          :eds_html_fulltext,
          :eds_images,
          :eds_all_links,
          :eds_fulltext_links,
          :eds_non_fulltext_links
      ]

      # Raw record as returned by the \EDS API via search or retrieve
      attr_accessor(*ATTRIBUTES)

      def attributes
        ATTRIBUTES.map{|attribute| self.send(attribute) }
      end

      # Creates a search or retrieval result record
      def initialize(results_record)

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

        # accessors:
        @eds_accession_number = @record['Header']['An'].to_s
        @eds_database_id = @record['Header']['DbId'].to_s
        @eds_database_name = @record['Header']['DbLabel']
        @eds_access_level = @record['Header']['AccessLevel']
        @eds_relevancy_score =  @record['Header']['RelevancyScore']
        @eds_title = title
        @eds_source_title = source_title
        @eds_other_titles = other_titles
        @eds_abstract = abstract
        @eds_authors = bib_authors || get_item_data_by_name('Author')
        @eds_author_affiliations = get_item_data_by_name('AffiliationAuthor')
        @eds_subjects = bib_subjects || get_item_data_by_name('Subject')
        @eds_subjects_geographic = get_item_data_by_name('SubjectGeographic')
        @eds_subjects_person = get_item_data_by_name('SubjectPerson')
        @eds_author_supplied_keywords = get_item_data_by_label('Author-Supplied Keywords')
        @eds_notes = notes
        @eds_languages = get_item_data_by_name('Language') || bib_languages
        @eds_page_count = bib_page_count
        @eds_page_start = bib_page_start
        @eds_physical_description = get_item_data_by_name('PhysDesc')
        @eds_publication_type = @record['Header']['PubType'] || get_item_data_by_name('TypePub')
        @eds_publication_type_id = @record['Header']['PubTypeId']
        @eds_publication_date = bib_publication_date || get_item_data_by_name('DatePub')
        @eds_publication_year = bib_publication_year || get_item_data_by_name('DatePub')
        @eds_publication_info = get_item_data_by_label('Publication Information')
        @eds_document_type = get_item_data_by_name('TypeDocument')
        @eds_document_doi = get_item_data_by_name('DOI') || bib_doi
        @eds_document_oclc = get_item_data_by_label('OCLC')
        @eds_issn_print = get_item_data_by_name('ISSN') || bib_issn_print
        @eds_issns = bib_issns
        @eds_isbn_print = bib_isbn_print
        @eds_isbns_related = item_related_isbns
        @eds_isbn_electronic = bib_isbn_electronic
        @eds_isbns = bib_isbns || item_related_isbns
        @eds_series =  get_item_data_by_name('SeriesInfo')
        @eds_volume = bib_volume
        @eds_issue = bib_issue
        @eds_covers = images
        @eds_cover_thumb_url = cover_thumb_url
        @eds_cover_medium_url = cover_medium_url
        @eds_fulltext_word_count = get_item_data_by_name('FullTextWordCount').to_i
        @eds_result_id = @record['ResultId']
        @eds_plink = @record['PLink']
        @eds_html_fulltext = html_fulltext
        @eds_images = images
        @eds_all_links = all_links
        @eds_fulltext_links = fulltext_links
        @eds_non_fulltext_links = non_fulltext_links
        @id = @eds_database_id + '__' + @eds_accession_number.gsub(/\./,'_')

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
        # _retval = get_item_data_by_name('Title') || bib_title
        _retval = bib_title || get_item_data_by_name('Title')
        # TODO: make this configurable
        if _retval.nil?
          _retval = 'This title is unavailable for guests, please login to see more information.'
        end
        CGI.unescapeHTML(_retval)
      end

      # The source title (e.g., Journal)
      def source_title
        _retval = bib_source_title || get_item_data_by_name('TitleSource')
        _reval = nil? if _retval == title # suppress if it's identical to title
        _retval.nil?? nil : CGI.unescapeHTML(_retval)
      end

      # Other alternative titles.
      def other_titles
        _retval = get_item_data_by_name('TitleAlt')
        _retval.nil?? nil : CGI.unescapeHTML(_retval)
      end

      # The abstract
      def abstract
        _retval = get_item_data_by_name('Abstract')
        _retval.nil?? nil : CGI.unescapeHTML(_retval)
      end

      # Notes
      def notes
        _retval = get_item_data_by_name('Note')
        _retval.nil?? nil : CGI.unescapeHTML(_retval)
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

      # Fulltext.
      def html_fulltext
        if @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',0) == '1'
          @record.fetch('FullText',{}).fetch('Text',{})['Value']
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

      # related ISBNs
      def item_related_isbns
        isbns = get_item_data_by_label('Related ISBNs')
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
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'pdf'})
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
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'ebook-pdf'})
            end
          end
        end

        if ebscolinks.count > 0
          ebscolinks.each do |ebscolink|
            if ebscolink['Type'] == 'ebook-epub'
              link_label = 'ePub eBook Full Text'
              link_icon = 'ePub eBook Full Text Icon'
              link_url = ebscolink['Url'] || 'detail'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'ebook-epub'})
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
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'cataloglink'})
            end
          end
        end

        if ebscolinks.count > 0
          ebscolinks.each do |ebscolink|
            if ebscolink['Type'] == 'other'
              link_label = 'Linked Full Text'
              link_icon = 'Linked Full Text Icon'
              link_url = ebscolink['Url'] || 'detail'
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'smartlinks'})
            end
          end
        end

        ft_customlinks = @record.fetch('FullText',{}).fetch('CustomLinks',{})
        if ft_customlinks.count > 0
          ft_customlinks.each do |ft_customlink|
            link_url = ft_customlink['Url']
            link_label = ft_customlink['Text']
            link_icon = ft_customlink['Icon']
            links.push({url: link_url, label: link_label, icon: link_icon, type: 'customlink-fulltext'})
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
            link_label = other_customlink['Text']
            link_icon = other_customlink['Icon']
            links.push({url: link_url, label: link_label, icon: link_icon, type: 'customlink-other'})
          end
        end

        links
      end

      # ====================================================================================
      # ITEM DATA HELPERS
      # ====================================================================================

      # look up by 'Name' and return 'Data'
      def get_item_data_by_name(name)
        if @items.empty?
          nil
        else
          _item_property = @items.find{|item| item['Name'] == name}
          if _item_property.nil?
            nil
          else
            _item_property['Data']
          end
        end
      end

      # look up by 'Label' and return 'Data'
      def get_item_data_by_label(label)
        if @items.empty?
          nil
        else
          _item_property = @items.find{|item| item['Label'] == label}
          if _item_property.nil?
            nil
          else
            _item_property['Data']
          end
        end
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
              var != :@bib_relationships
            hash[var.to_s.sub(/^@/, '')] = instance_variable_get(var)
          end
        end
        if all_links
          hash['eds_fulltext_link'] = { 'id' => @eds_database_id + '__' + @eds_accession_number.gsub(/\./,'_'),
                                        'links' => all_links }
        end

        hash
      end

      # this is used to generate solr fields
      # def to_hash(type = 'compact')
      #   hash = {}
      #
      #   # information typically required by all views
      #   if database_id && accession_number
      #     safe_an = accession_number.gsub(/\./,'_')
      #     hash['eds_id'] = database_id + '__' + safe_an
      #   end
      #   unless title.nil?
      #     hash['eds_title'] = title.gsub('<highlight>', '').gsub('</highlight>', '')
      #   end
      #   if source_title
      #     hash['eds_source_title'] = source_title
      #   end
      #   if publication_year
      #     hash['eds_publication_year'] = publication_year
      #   end
      #   if authors
      #     hash['eds_authors'] = authors.to_s
      #   end
      #   if publication_type
      #     hash['eds_publication_type'] = publication_type.to_s
      #   end
      #   if languages
      #     if languages.kind_of?(Array)
      #       hash['eds_language'] = languages.join(', ')
      #     else
      #       hash['eds_language'] = languages.to_s
      #     end
      #   end
      #   if publisher_info
      #     hash['eds_publisher_info'] = publisher_info
      #   end
      #   if abstract
      #     hash['eds_abstract'] = abstract
      #   end
      #   if cover_thumb_url
      #     hash['eds_cover_thumb_url'] = cover_thumb_url
      #   end
      #   if cover_medium_url
      #     hash['eds_cover_medium_url'] = cover_medium_url
      #   end
      #   if all_links
      #     hash['eds_fulltext_link'] = { 'id' => database_id + '__' + safe_an, 'links' => all_links}
      #   end
      #
      #   # extra information typically required by detailed item views
      #   if type == 'verbose'
      #     if all_links
      #       hash['eds_links'] = all_links
      #     end
      #     if doi
      #       hash['eds_doi'] = doi
      #     end
      #     if html_fulltext
      #       hash['eds_html_fulltext'] = html_fulltext
      #     end
      #   end
      #
      #   hash
      # end

      def to_solr
        # solr response
        # item_hash = to_hash 'verbose'
        item_hash = to_attr_hash
        solr_response =
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
        # puts 'SOLR RESPONSE: ' + solr_response.inspect
        solr_response
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

