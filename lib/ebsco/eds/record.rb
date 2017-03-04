require 'yaml'
require 'json'
require 'bibtex'

module EBSCO

  module EDS

    # A single search result
    class Record

      # Raw record as returned by the \EDS API via search or retrieve
      attr_reader :record

      # Lookup table of databases that have their labels suppressed in the response.
      DBS = YAML::load_file(File.join(__dir__, 'settings.yml'))['databases']

      # Creates a search or retrieval result record
      def initialize(results_record)

        if results_record.key? 'Record'
          @record = results_record['Record'] # single record returned by retrieve api
        else
          @record = results_record  # set of records returned by search api
        end

        @items = @record.fetch('Items', {})

        @bib_entity = @record.fetch('RecordInfo', {})
                          .fetch('BibRecord', {})
                          .fetch('BibEntity', {})

        @bib_relationships = @record.fetch('RecordInfo', {})
                                 .fetch('BibRecord', {})
                                 .fetch('BibRelationships', {})

        @bib_part = @record.fetch('RecordInfo', {})
                          .fetch('BibRecord', {})
                          .fetch('BibRelationships', {})
                          .fetch('IsPartOfRelationships', {})[0]

        @bibtex = BibTeX::Entry.new
      end

      # \Options hash containing accession number and database ID. This can be passed to the retrieve method.
      def retrieve_options
        options = {}
        options['an'] = self.accession_number
        options['dbid'] = self.database_id
        options
      end

      # The accession number.
      def accession_number
        header_an
      end

      # The database ID.
      def database_id
        header_db_id
      end

      # The database name or label.
      def database_name
        header_db_label
      end

      # The access level.
      def access_level
        header_access_level
      end

      # The search relevancy score.
      def relevancy_score
        header_score
      end

      # The title.
      def title
        get_item_data_by_name('Title') || bib_title
      end

      # The source title (e.g., Journal)
      def source_title
        bib_source_title || get_item_data_by_name('TitleSource')
      end

      # Other alternative titles.
      def other_titles
        get_item_data_by_name('TitleAlt')
      end

      # The abstract
      def abstract
        get_item_data_by_name('Abstract')
      end

      # The list of authors
      def authors
         bib_authors || get_item_data_by_name('Author')
      end

      # The author affiliations
      def author_affiliations
        get_item_data_by_name('AffiliationAuthor')
      end

      # The list of subject terms.
      def subjects
        bib_subjects || get_item_data_by_name('Subject')
      end

      # The list of geographic subjects
      def subjects_geographic
        get_item_data_by_name('SubjectGeographic')
      end

      # The list of person subjects
      def subjects_person
        get_item_data_by_name('SubjectPerson')
      end

      # Author supplied keywords
      def author_supplied_keywords
        get_item_data_by_label('Author-Supplied Keywords')
      end

      # Notes
      def notes
        get_item_data_by_name('Note')
      end

      # Languages
      def languages
        get_item_data_by_name('Language') || bib_languages
      end

      # Total number of pages.
      def page_count
        bib_page_count
      end

      # Starting page number.
      def page_start
        bib_page_start
      end

      # Physical description.
      def physical_description
        get_item_data_by_name('PhysDesc')
      end

      # Publication type.
      def publication_type
        header_publication_type || get_item_data_by_name('TypePub')
      end

      # Publication type ID.
      def publication_type_id
        header_publication_type_id
      end

      # Publication date.
      def publication_date
        bib_publication_date || get_item_data_by_name('DatePub')
      end

      # Publication year.
      def publication_year
        bib_publication_year || get_item_data_by_name('DatePub')
      end

      # Publisher information.
      def publisher_info
        get_item_data_by_label('Publication Information')
      end

      # Document type.
      def document_type
        get_item_data_by_name('TypeDocument')
      end

      # DOI identifier.
      def doi
        get_item_data_by_name('DOI') || bib_doi
      end

      # OCLC identifier.
      def oclc
        get_item_data_by_label('OCLC')
      end

      #  Prind ISSN
      def issn_print
        get_item_data_by_name('ISSN') || bib_issn_print
      end

      # List of ISSNs
      def issns
        bib_issns
      end

      # List of ISBNs
      def isbns
        bib_isbns | item_related_isbns
      end

      # Print ISBN
      def isbn_print
        bib_isbn_print
      end

      # Electronic ISBN
      def isbn_electronic
        bib_isbn_electronic
      end

      # Series information.
      def series
        get_item_data_by_name('SeriesInfo')
      end

      # Volume
      def volume
        bib_volume
      end

      # Issue
      def issue
        bib_issue
      end

      # Cover images
      def covers
        images
      end

      # Cover image - thumbnail size link
      def cover_thumb_url
        images('thumb').first[:src]
      end

      # Cover image - medium size link
      def cover_medium_url
        images('medium').first[:src]
      end

      # Word count for fulltext.
      def fulltext_word_count
        get_item_data_by_name('FullTextWordCount').to_i
      end

      # --
      # ====================================================================================
      # GENERAL: ResultId, PLink, ImageInfo, CustomLinks, FullText
      # ====================================================================================
      # ++

      # Result ID.
      def result_id
        @record['ResultId']
      end

      # EBSCO's persistent link.
      def plink
        @record['PLink']
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

      # --
      # ====================================================================================
      # LINK HELPERS
      # ====================================================================================
      # ++

      # A list of all available links.
      def all_links
        self.fulltext_links + self.non_fulltext_links
      end

      # The first fulltext link.
      def fulltext_link
        self.fulltext_links.first || {}
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

        htmlfulltextcheck = @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',{})
        if htmlfulltextcheck == '1'
          link_url = 'detail'
          link_label = 'Full Text in Browser'
          link_icon = 'Full Text in Browser Icon'
          links.push({url: link_url, label: link_label, icon: link_icon, type: 'html'})
        end

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
            if item['Group'] == 'Url'
              if item['Data'].include? 'linkTerm=&quot;'
                link_start = item['Data'].index('linkTerm=&quot;')+15
                link_url = item['Data'][link_start..-1]
                link_end = link_url.index('&quot;')-1
                link_url = link_url[0..link_end]
                link_label_start = item['Data'].index('link&gt;')+8
                link_label = item['Data'][link_label_start..-1]
                link_label = link_label.strip
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
              links.push({url: link_url, label: link_label, icon: link_icon, type: 'smartlinks+'})
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
      
      #:nodoc: all
      # No need to document methods below

      # Experimental bibtex support.
      def retrieve_bibtex

        @bibtex.key = self.accession_number
        @bibtex.title = self.title
        if self.bib_authors_list.length > 0
          @bibtex.author = self.bib_authors_list.join(' and ').chomp
        end
        @bibtex.year = self.publication_year.to_i

        # bibtex type
        _type = self.publication_type
        case _type
          when 'Academic Journal'
            @bibtex.type = :article
            @bibtex.journal = self.source_title
            if self.issue
              @bibtex.issue = self.issue
            end
            if self.volume
              @bibtex.number = self.volume
            end
            if self.page_start && self.page_count
              @bibtex.pages = self.page_start + '-' + (self.page_start.to_i + self.page_count.to_i-1).to_s
            end
            if self.bib_publication_month
              @bibtex.month = self.bib_publication_month.to_i
            end
          when 'Conference'
            @bibtex.type = :conference
            @bibtex.booktitle = self.source_title
            if self.issue
              @bibtex.issue = self.issue
            end
            if self.volume
              @bibtex.number = self.volume
            end
            if self.page_start && self.page_count
              @bibtex.pages = self.page_start + '-' + (self.page_start.to_i + self.page_count.to_i-1).to_s
            end
            if self.bib_publication_month
              @bibtex.month = self.bib_publication_month.to_i
            end
            if self.publisher_info
              @bibtex.publisher = self.publisher_info
            end
            if self.series
              @bibtex.series = self.series
            end
          when 'Book', 'eBook'
            @bibtex.type = :book
            if self.publisher_info
              @bibtex.publisher = self.publisher_info
            end
            if self.series
              @bibtex.series = self.series
            end
            if self.bib_publication_month
              @bibtex.month = self.bib_publication_month.to_i
            end
            if self.isbns
              @bibtex.isbn = self.isbns.first
            end
          else
            @bibtex.type = :other
        end
        @bibtex
      end

      # ====================================================================================
      # HEADER: DbId, DbLabel, An, PubType, PubTypeId, AccessLevel
      # ====================================================================================

      def header_an
        @record['Header']['An'].to_s
      end

      def header_db_id
        @record['Header']['DbId'].to_s
      end

      # only available from search not retrieve
      def header_score
        @record['Header']['RelevancyScore']
      end

      def header_publication_type
        @record['Header']['PubType']
      end

      def header_publication_type_id
        @record['Header']['PubTypeId']
      end

      def header_db_label
        DBS[self.database_id.upcase] || @record['Header']['DbLabel']
      end

      # not sure the rules for when this appears or not - RecordInfo.AccessInfo?
      def header_access_level
        @record['Header']['AccessLevel']
      end

      # ====================================================================================
      # ITEMS
      # ====================================================================================

      # look up by 'Name' and return 'Data'
      def get_item_data_by_name(name)
        _item_property = @items.find{|item| item['Name'] == name}
        if _item_property.nil?
          nil
        else
          _item_property['Data']
        end
      end

      # look up by 'Label' and return 'Data'
      def get_item_data_by_label(label)
        _item_property = @items.find{|item| item['Label'] == label}
        if _item_property.nil?
          nil
        else
          _item_property['Data']
        end
      end

      def item_related_isbns
        get_item_data_by_label('Related ISBNs').split(' ').map!{|item| item.gsub(/\.$/, '')}
      end

      # ====================================================================================
      # BIB ENTITY
      # ====================================================================================

      def bib_title
        @bib_entity.fetch('Titles', {}).find{|item| item['Type'] == 'main'}['TitleFull']
      end

      def bib_authors
        @bib_relationships.deep_find('NameFull').join('; ')
      end

      def bib_authors_list
        @bib_relationships.deep_find('NameFull')
      end

      def bib_subjects
        @bib_entity.deep_find('SubjectFull')
      end

      def bib_languages
        @bib_entity.fetch('Languages', {}).map{|lang| lang['Text']}
      end

      # def bib_pages
      #   @bib_entity.fetch('PhysicalDescription', {})['Pagination']
      # end

      def bib_page_count
        @bib_entity.deep_find('PageCount').first
      end

      def bib_page_start
        @bib_entity.deep_find('StartPage').first
      end

      def bib_doi
        @bib_entity.fetch('Identifiers',{}).find{|item| item['Type'] == 'doi'}['Value']
      end

      # ====================================================================================
      # BIB - IS PART OF (journal, book)
      # ====================================================================================

      def bib_source_title
        @bib_part.fetch('BibEntity',{}).fetch('Titles',{}).find{|item| item['Type'] == 'main'}['TitleFull']
      end

      def bib_issn_print
        @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'issn-print'}['Value']
      end

      def bib_issn_electronic
        @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'issn-electronic'}['Value']
      end

      def bib_issns
        issns = []
        @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).each do |id|
          if id['Type'].include?('issn') && !id['Type'].include?('locals')
            issns.push(id['Value'])
          end
        end
        issns
      end

      def bib_isbn_print
        @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'isbn-print'}['Value']
      end

      def bib_isbn_electronic
        @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).find{|item| item['Type'] == 'isbn-electronic'}['Value']
      end

      # todo: make this generic and take an optional parameter for type
      def bib_isbns
        isbns = []
        @bib_part.fetch('BibEntity',{}).fetch('Identifiers',{}).each do |id|
          if id['Type'].include?('isbn') && !id['Type'].include?('locals')
            isbns.push(id['Value'])
          end
        end
        isbns
      end

      def bib_publication_date
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
      end

      def bib_publication_year
        _date = @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).find{|item| item['Type'] == 'published'}
        if _date
          _date.has_key?('Y') ? _date['Y'] : nil
        else
          nil
        end
      end

      def bib_publication_month
        _date = @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).find{|item| item['Type'] == 'published'}
        if _date
          _date.has_key?('M') ? _date['M'] : nil
        else
          nil
        end
      end

      def bib_volume
        @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).find{|item| item['Type'] == 'volume'}['Value']
      end

      def bib_issue
        @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).find{|item| item['Type'] == 'issue'}['Value']
      end

      # this is used to generate solr fields
      def to_hash
        hash = {}
        hash['id'] = database_id + '-' + accession_number
        hash['title_display'] = title.gsub('&lt;highlight&gt;', '').gsub('&lt;/highlight&gt;', '')
        hash['pub_date'] = publication_year
        hash['author_display'] = authors.to_s
        hash['format'] = publication_type.to_s
        hash['language_facet'] = languages.join(', ')
        hash
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

