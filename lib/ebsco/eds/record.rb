require 'yaml'
require 'json'

module EBSCO

  module EDS

    class Record

      attr_accessor :record

      DBS = YAML::load_file(File.join(__dir__, 'settings.yml'))['databases']

      def initialize(results_record)
        #puts results_record.to_yaml
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
      end

      # ====================================================================================
      # PUBLIC PROPERTIES
      # ====================================================================================

      def accession_number
        header_an
      end

      def database_id
        header_db_id
      end

      def database_name
        header_db_label
      end

      # RecordInfo.AccessInfo?
      def access_level
        header_access_level
      end

      def relevancy_score
        header_score
      end

      def title
        get_item_data_by_name('Title') || bib_title
      end

      def source_title
        bib_source_title || get_item_data_by_name('TitleSource')
      end

      def other_titles
        get_item_data_by_name('TitleAlt')
      end

      def abstract
        get_item_data_by_name('Abstract')
      end

      def authors
         bib_authors || get_item_data_by_name('Author')
      end

      def author_affiliations
        get_item_data_by_name('AffiliationAuthor')
      end

      def subjects
        bib_subjects || get_item_data_by_name('Subject')
      end

      def subjects_geographic
        get_item_data_by_name('SubjectGeographic')
      end

      def subjects_person
        get_item_data_by_name('SubjectPerson')
      end

      def author_supplied_keywords
        get_item_data_by_label('Author-Supplied Keywords')
      end

      def notes
        get_item_data_by_name('Note')
      end

      def languages
        get_item_data_by_name('Language') || bib_languages
      end

      def page_count
        bib_page_count
      end

      def page_start
        bib_page_start
      end

      def physical_description
        get_item_data_by_name('PhysDesc')
      end

      def publication_type
        header_publication_type || get_item_data_by_name('TypePub')
      end

      def publication_type_id
        header_publication_type_id
      end

      def publication_date
        bib_publication_date || get_item_data_by_name('DatePub')
      end

      def publication_year
        bib_publication_year || get_item_data_by_name('DatePub')
      end

      def publisher_info
        get_item_data_by_label('Publication Information')
      end

      def document_type
        get_item_data_by_name('TypeDocument')
      end

      def doi
        get_item_data_by_name('DOI') || bib_doi
      end

      def oclc
        get_item_data_by_label('OCLC')
      end

      #  item includes a dash, bib may not
      def issn_print
        get_item_data_by_name('ISSN') || bib_issn_print
      end

      # merge and dedupe item and bib?
      def issns
        bib_issns
      end

      def isbns
        bib_isbns | item_related_isbns
      end

      def isbn_print
        bib_isbn_print
      end

      def isbn_electronic
        bib_isbn_electronic
      end

      def series
        get_item_data_by_name('SeriesInfo')
      end

      def volume
        bib_volume
      end

      def issue
        bib_issue
      end

      def covers
        images
      end

      def cover_thumb_url
        images('thumb').first[:src]
      end

      def cover_medium_url
        images('medium').first[:src]
      end

      def fulltext_word_count
        get_item_data_by_name('FullTextWordCount').to_i
      end

      # ====================================================================================
      # GENERAL: ResultId, PLink, ImageInfo, CustomLinks, FullText
      # ====================================================================================

      def result_id
        @record['ResultId']
      end

      def plink
        @record['PLink']
      end

      def html_fulltext
        if @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',0) == '1'
          @record.fetch('FullText',{}).fetch('Text',{})['Value']
        else
          nil
        end
      end

      # cover art - books only?
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

      # custom links?

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
        _date['Y'] + '-' + _date['M'] + '-' + _date['D']
      end

      def bib_publication_year
        _date = @bib_part.fetch('BibEntity',{}).fetch('Dates',{}).find{|item| item['Type'] == 'published'}
        _date['Y']
      end

      def bib_volume
        @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).find{|item| item['Type'] == 'volume'}['Value']
      end

      def bib_issue
        @bib_part.fetch('BibEntity',{}).fetch('Numbering',{}).find{|item| item['Type'] == 'issue'}['Value']
      end

      # ====================================================================================
      # LINK HELPERS
      # ====================================================================================

      def all_links
        self.fulltext_links + self.non_fulltext_links
      end

      def best_fulltext_link
        self.fulltext_links.first || {}
      end

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

      def retrieve_options
        options = {}
        options['an'] = self.accession_number
        options['dbid'] = self.database_id
        options
      end
    end

  end
end

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

