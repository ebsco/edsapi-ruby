require 'yaml'

module EBSCO

  class Record

    attr_accessor :record, :bib_entity, :bib_relationships

    DBS = YAML::load_file(File.join(__dir__, 'settings.yml'))['databases']

    def initialize(results_record)
      if results_record.key? 'Record'
        @record = results_record['Record'] # single record returned by retrieve api
      else
        @record = results_record  # set of records returned by search api
      end
      @bib_entity = @record.fetch('RecordInfo', {}).fetch('BibRecord', {}).fetch('BibEntity', {})
      @bib_relationships = @record.fetch('RecordInfo', {}).fetch('BibRecord', {}).fetch('BibRelationships', {})
      @items = @record.fetch('Items', {})
    end

    def resultid
      @record['ResultId']
    end

    # Header Info
    def an
      @record['Header']['An'].to_s
    end

    def dbid
      @record['Header']['DbId'].to_s
    end

    # only available from search not retrieve
    def score
      @record['Header']['RelevancyScore']
    end

    def pubtype
      @record['Header']['PubType']
    end

    def pubtype_id
      @record['Header']['PubTypeId']
    end

    def db_label
      if DBS.key?(self.dbid.upcase)
        DBS[self.dbid.upcase];
      else
        @record['Header']['DbLabel']
      end
    end

    def access_level
      @record['Header']['AccessLevel']
    end

    # plink
    def plink
      @record['PLink']
    end

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

    def title
      @items.find{|item| item['Group'] == 'Ti'}['Data'] ||
          @bib_entity.fetch('Titles', {}).find{|item| item['Type'] == 'main'}['TitleFull']
    end

    def title_raw
      @bib_entity.fetch('Titles', {}).find{|item| item['Type'] == 'main'}['TitleFull'] ||
          @items.find{|item| item['Group'] == 'Ti'}['Data']
    end

    def authors
      @items.find{|item| item['Group'] == 'Au'}['Data'] || @bib_relationships.deep_find('NameFull').join('; ')
    end

    def authors_raw
      @bib_relationships.deep_find('NameFull').join('; ') || @items.find{|item| item['Group'] == 'Au'}['Data']
    end

    def subjects
      @items.find{|item| item['Group'] == 'Su'}['Data'] || @bib_entity.fetch('Subjects', {}).map{|subject| subject}
    end

    def subjects_raw
      @bib_entity.fetch('Subjects', {}).map{|subject| subject} || @items.find{|item| item['Group'] == 'Su'}['Data']
    end

    def languages
      language_section = @bib_entity.fetch('Languages', {})

      if language_section.count > 0
        langs = []
        language_section.each do |language|
          langs.push(language['Text'])
        end
        langs
      end
      []
    end

    def pages
      pagination_section = @bib_entity.fetch('PhysicalDescription', {})

      if pagination_section.count > 0
        pagination_section['Pagination']
      end
      {}
    end

    def abstract
      items = @record.fetch('Items',{})
      if items.count > 0
        items.each do |item|
          if item['Group'] == 'Ab'
            item['Data']
          end
        end
      end

      nil
    end

    def html_fulltext
      htmlfulltextcheck = @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',0)
      if htmlfulltextcheck == '1'
        @record.fetch('FullText',{}).fetch('Text',{})['Value']
      end
      nil
    end

    def source

      items = @record.fetch('Items',{})
      if items.count > 0
        items.each do |item|
          if item['Group'] == 'Src'
            item['Data']
          end
        end
      end

      nil
    end

    def source_title

      unless self.source.nil?
        ispartof = @bib_relationships.fetch('IsPartOfRelationships', {})

        if ispartof.count > 0
          ispartof.each do |contributor|
            titles = contributor.fetch('BibEntity',{}).fetch('Titles',{})
            titles.each do |title_src|
              if title_src['Type'] == 'main'
                title_src['TitleFull']
              end
            end
          end
        end
      end
      nil

    end

    def numbering
      ispartof = @bib_relationships.fetch('IsPartOfRelationships', {})

      if ispartof.count > 0
        numbering = []
        ispartof.each do |contributor|
          nums = contributor.fetch('BibEntity',{}).fetch('Numbering',{})
          nums.each do |num|
            numbering.push(num)
          end
        end
        numbering
      end

      []
    end

    def doi
      ispartof = @bib_entity.fetch('Identifiers', {})

      if ispartof.count > 0
        ispartof.each do |ids|
          if ids['Type'] == 'doi'
            ids['Value']
          end
        end
      end

      nil
    end

    def isbns

      ispartof = @bib_relationships.fetch('IsPartOfRelationships', {})

      if ispartof.count > 0
        issns = []
        ispartof.each do |part_of|
          ids = part_of.fetch('BibEntity',{}).fetch('Identifiers',{})
          ids.each do |id|
            if id['Type'].include?('isbn') && !id['Type'].include?('locals')
              issns.push(id)
            end
          end
        end
        issns
      end
      []
    end

    def issns

      ispartof = @bib_relationships.fetch('IsPartOfRelationships', {})

      if ispartof.count > 0
        issns = []
        ispartof.each do |part_of|
          ids = part_of.fetch('BibEntity',{}).fetch('Identifiers',{})
          ids.each do |id|
            if id['Type'].include?('issn') && !id['Type'].include?('locals')
              issns.push(id)
            end
          end
        end
        issns
      end
      []
    end

    def source_isbn
      unless self.source.nil?

        ispartof = @bib_relationships.fetch('IsPartOfRelationships', {})

        if ispartof.count > 0
          issns = []
          ispartof.each do |part_of|
            ids = part_of.fetch('BibEntity',{}).fetch('Identifiers',{})
            ids.each do |id|
              if id['Type'].include?('isbn') && !id['Type'].include?('locals')
                issns.push(id)
              end
            end
          end
          issns
        end
      end
      []
    end



    def pubyear
      ispartofs = @bib_relationships.fetch('IsPartOfRelationships', {})
      if ispartofs.count > 0
        dates = ispartofs[0]['BibEntity'].fetch('Dates',{})
        if dates.count > 0
          dates.each do |date|
            if date['Type'] == 'published'
              date['Y']
            end
          end
        end
      end
      nil
    end

    def pubdate
      ispartofs = @bib_relationships.fetch('IsPartOfRelationships', {})
      if ispartofs.count > 0
        dates = ispartofs[0]['BibEntity'].fetch('Dates',{})
        if dates.count > 0
          dates.each do |date|
            if date['Type'] == 'published'
              date['Y']+'-'+date['M']+'-'+date['D']
            end
          end
        end
      end
      nil
    end

    def all_links
      self.fulltext_links + self.nonfulltext_links
    end

    def fulltext_links

      links = []

      ebscolinks = @record.fetch('FullText',{}).fetch('Links',{})
      if ebscolinks.count > 0
        ebscolinks.each do |ebscolink|
          if ebscolink['Type'] == 'pdflink'
            link_label = 'PDF Full Text'
            link_icon = 'PDF Full Text Icon'
            if ebscolink.key?('Url')
              link_url = ebscolink['Url']
            else
              link_url = 'detail';
            end
            links.push({url: link_url, label: link_label, icon: link_icon, type: 'pdf'})
          end
        end
      end

      htmlfulltextcheck = @record.fetch('FullText',{}).fetch('Text',{}).fetch('Availability',0)
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
            if ebscolink.key?('Url')
              link_url = ebscolink['Url']
            else
              link_url = 'detail';
            end
            links.push({url: link_url, label: link_label, icon: link_icon, type: 'ebook-pdf'})
          end
        end
      end

      if ebscolinks.count > 0
        ebscolinks.each do |ebscolink|
          if ebscolink['Type'] == 'ebook-epub'
            link_label = 'ePub eBook Full Text'
            link_icon = 'ePub eBook Full Text Icon'
            if ebscolink.key?('Url')
              link_url = ebscolink['Url']
            else
              link_url = 'detail';
            end
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
            if ebscolink.key?('Url')
              link_url = ebscolink['Url']
            else
              link_url = 'detail';
            end
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

    def nonfulltext_links
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

    def best_fulltext_link
      if self.fulltext_links.count > 0
        self.fulltext_links[0]
      end
      {}
    end

    def retrieve_options
      options = {}
      options['an'] = self.an
      options['dbid'] = self.dbid
      options
    end
  end

end

# monkey patch
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