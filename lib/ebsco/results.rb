require 'ebsco/record'
require 'yaml'

module EBSCO

  class Results

    attr_accessor :results, :records, :db_label, :research_starters, :publication_match

    DBS = YAML::load_file(File.join(__dir__, 'settings.yml'))['databases']

    def initialize(search_results)

      @results = search_results
      # puts @results.inspect

      # GENERAL RECORDS
      @records = []
      if stat_total_hits > 0
        @results['SearchResult']['Data']['Records'].each { |record| @records.push(EBSCO::Record.new(record)) }
      end

      # RESEARCH STARTERS
      @research_starters = []
      _related_records = @results.fetch('SearchResult',{}).fetch('RelatedContent',{}).fetch('RelatedRecords',{})
      if _related_records.count > 0
        _related_records.each do |related_item|
          if related_item['Type'] == 'rs'
            rs_entries = related_item.fetch('Records',{})
            if rs_entries.count > 0
              rs_entries.each do |rs_record|
                @research_starters.push(EBSCO::Record.new(rs_record))
              end
            end
          end
        end
      end

      # PUBLICATION MATCHES
      @publication_match = []
      _related_publications = @results.fetch('SearchResult',{}).fetch('RelatedContent',{}).fetch('RelatedPublications',{})
      if _related_publications.count > 0
        _related_publications.each do |related_item|
          if related_item['Type'] == 'emp'
            _publication_matches = related_item.fetch('PublicationRecords',{})
            if _publication_matches.count > 0
              _publication_matches.each do |publication_record|
                @publication_match.push(EBSCO::Record.new(publication_record))
              end
            end
          end
        end
      end

    end

    def stat_total_hits
      _hits = @results.fetch('SearchResult',{}).fetch('Statistics',{}).fetch('TotalHits',{})
      _hits == {} ? 0 : _hits
    end

    def stat_total_time
      @results['SearchResult']['Statistics']['TotalSearchTime']
    end

    def search_criteria
      @results['SearchRequest']['SearchCriteria']
    end

    def search_criteria_with_actions
      @results['SearchRequest']['SearchCriteriaWithActions']
    end

    def retrieval_criteria
      @results['SearchRequest']['RetrievalCriteria']
    end

    # "Queries"=>[{"BooleanOperator"=>"AND", "Term"=>"volcano"}]
    def search_queries
      @results['SearchRequest']['SearchCriteria']['Queries']
    end

    # def query_string
    #   @results['SearchRequest']['QueryString']
    # end

    # def current_search
    #   CGI::parse(self.querystring)
    # end

    def page_number
      @results['SearchRequest']['RetrievalCriteria']['PageNumber'] || 1
    end

    def applied_facets

      af = []
      applied_facets_section = @results['SearchRequest'].fetch('SearchCriteriaWithActions',{}).fetch('FacetFiltersWithAction',{})
      applied_facets_section.each do |applied_facets|
        applied_facets.fetch('FacetValuesWithAction',{}).each do |applied_facet|
          af.push(applied_facet)
#					unless applied_facet['FacetValuesWithAction'].nil?
#						applied_facet_values = applied_facet.fetch('FacetValuesWithAction',{})
#						applied_facet_values.each do |applied_facet_value|
#							af.push(applied_facet_value)
#						end
#					end
        end
      end
      af
    end

    def applied_limiters
      af = []
      applied_limters_section = @results['SearchRequest'].fetch('SearchCriteriaWithActions',{}).fetch('LimitersWithAction',{})
      applied_limters_section.each do |applied_limter|
        af.push(applied_limter)
      end
      af
    end

    def applied_expanders
      af = []
      applied_expanders_section = @results['SearchRequest'].fetch('SearchCriteriaWithActions',{}).fetch('ExpandersWithAction',{})
      applied_expanders_section.each do |applied_explander|
        af.push(applied_explander)
      end
      af
    end

    def applied_publications
      retval = []
      applied_publications_section = @results['SearchRequest'].fetch('SearchCriteriaWithActions',{}).fetch('PublicationWithAction',{})
      applied_publications_section.each do |item|
        retval.push(item)
      end
      retval
    end

    def database_stats
      databases = []
      databases_facet = @results['SearchResult']['Statistics']['Databases']
      databases_facet.each do |database|
        if DBS.key?(database['Id'].upcase)
          db_label = DBS[database['Id'].upcase];
        else
          db_label = database['Label']
        end
        databases.push({id: database['Id'], hits: database['Hits'], label: db_label})
      end
      databases
    end

    def facets (facet_provided_id = 'all')
      facets_hash = []
      available_facets = @results.fetch('SearchResult',{}).fetch('AvailableFacets',{})
      available_facets.each do |available_facet|
        if available_facet['Id'] == facet_provided_id || facet_provided_id == 'all'
          facet_label = available_facet['Label']
          facet_id = available_facet['Id']
          facet_values = []
          available_facet['AvailableFacetValues'].each do |available_facet_value|
            facet_value = available_facet_value['Value']
            facet_count = available_facet_value['Count']
            facet_action = available_facet_value['AddAction']
            facet_values.push({value: facet_value, hitcount: facet_count, action: facet_action})
          end
          facets_hash.push(id: facet_id, label: facet_label, values: facet_values)
        end
      end
      facets_hash
    end

    def date_range
      mindate = @results['SearchResult']['AvailableCriteria']['DateRange']['MinDate']
      maxdate = @results['SearchResult']['AvailableCriteria']['DateRange']['MaxDate']
      minyear = mindate[0..3]
      maxyear = maxdate[0..3]
      {mindate: mindate, maxdate: maxdate, minyear:minyear, maxyear:maxyear}
    end

    def did_you_mean
      dym_suggestions = @results.fetch('SearchResult', {}).fetch('AutoSuggestedTerms',{})
      dym_suggestions.each do |term|
        return term
      end
      nil
    end

    def search_terms
      terms = []
      queries = @results.fetch('SearchRequest',{}).fetch('SearchCriteriaWithActions',{}).fetch('QueriesWithAction',{})
      queries.each do |query|
        query['Query']['Term'].split.each do |word|
          terms.push(word)
        end
      end
      terms
    end

  end

end