require 'ebsco/eds/jsonable'

module EBSCO

  module EDS

    class Options
      include JSONable
      attr_accessor :SearchCriteria, :RetrievalCriteria, :Actions, :Comment
      def initialize(options = {}, info)
  
        @SearchCriteria = EBSCO::EDS::SearchCriteria.new(options, info)

        @RetrievalCriteria = EBSCO::EDS::RetrievalCriteria.new(options, info)
  
        @Actions = []

        @Comment = ''

        # add DefaultOn=y Type=select limiters
        # info.available_limiters.each do |limiter|
        #   if limiter['DefaultOn'] == 'n' and limiter['Type'] == 'select'
        #     @Actions.push "addLimiter(#{limiter['Id']}:y)"
        #   end
        # end

        # add page default of 1
        unless options.has_key?('page') || options.has_key?('page_number')
          options['page'] = 1
        end

        options.each do |key, value|

          case key

            when :actions
              add_actions(options[:actions], info)

            # SOLR: Need to add page actions whenever other actions are present since the other actions
            # will always reset the page to 1 even though a PageNumber is present in RetrievalCriteria.
            when 'page', 'page_number'
              @Actions.push "GoToPage(#{value.to_i})"

          end
        end
  
      end
  
      def add_actions(actions, info)
        if actions.kind_of?(Array) && actions.count > 0
          actions.each do |item|
            #if is_valid_action(item, info)
            @Actions.push item
            #end
          end
        else
          #if is_valid_action(actions, info)
          @Actions = [actions]
          #else
          #end
        end
      end

      # def is_valid_action(action, info)
      #   # actions in info that require an enumerated value (e.g., addlimiter(LA99:Bulgarian))
      #   _available_actions = info.available_actions
      #   _defined_action = _available_actions.include? action
      #   # actions not enumerated in info (e.g., GoToPage(3))
      #   _available_standard_actions = ['GoToPage']
      #   _standard_action = _available_standard_actions.any? { |std| action.include? std }
      #   # actions in info that require a user supplied value (e.g., addlimiter(TI:value))
      #   _available_value_actions = %w{PG4 CS1 FM FT FR RV DT1 SO}
      #   _value_action = _available_value_actions.any? { |type| action.include? type }
      #
      #   if _value_action || _defined_action || _standard_action
      #     true
      #   else
      #     false
      #   end
      # end


      # Caution: experimental, not ready for production
      # query-1=AND,volcano&sort=relevance&includefacets=y&searchmode=all&autosuggest=n&view=brief&resultsperpage=20&pagenumber=1&highlight=y
      def to_query_string
        qs = 'query='

        # SEARCH CRITERIA:

        # query
        if @SearchCriteria.Queries[0].has_key? :BooleanOperator
          qs << @SearchCriteria.Queries[0][:BooleanOperator] + ","
        else
          qs << 'AND,'
        end
        if @SearchCriteria.Queries[0].has_key? :FieldCode
          qs << @SearchCriteria.Queries[0][:FieldCode] + ':'
        end
        qs << @SearchCriteria.Queries[0][:Term]

        # mode
        qs << '&searchmode=' + @SearchCriteria.SearchMode

        # facets
        qs << '&includefacets=' + @SearchCriteria.IncludeFacets

        # sort
        qs << '&sort=' + @SearchCriteria.Sort

        # auto-suggest
        qs << '&autosuggest=' + @SearchCriteria.AutoSuggest

        # auto-correct
        qs << '&autocorrect=' + @SearchCriteria.AutoCorrect

        # limiters
        unless @SearchCriteria.Limiters.nil?
          qs << '&limiter=' + @SearchCriteria.Limiters.join(',')
        end

        # expanders
        qs << '&expander=' + @SearchCriteria.Expanders.join(',')

        # facet filters
        unless @SearchCriteria.FacetFilters.nil?
          qs << '&facetfilter=1,' + @SearchCriteria.FacetFilters.join(',')
        end

        # related content
        unless @SearchCriteria.RelatedContent.nil?
          qs << '&relatedcontent=' + @SearchCriteria.RelatedContent.join(',')
        end

        # Retrieval Criteria
        unless @RetrievalCriteria.View.nil?
          qs << '&view=' + @RetrievalCriteria.View
        end
        unless @RetrievalCriteria.ResultsPerPage.nil?
          qs << '&resultsperpage=' + @RetrievalCriteria.ResultsPerPage.to_s
        end
        unless @RetrievalCriteria.PageNumber.nil?
          qs << '&pagenumber=' + @RetrievalCriteria.PageNumber.to_s
        end
        unless @RetrievalCriteria.Highlight.nil?
          qs << '&highlight=' + @RetrievalCriteria.Highlight.to_s
        end

        unless @Actions.nil?
          @Actions.each do |action|
            qs << '&action=' + action
          end
        end
        qs

      end

      end
  
    class SearchCriteria
      include JSONable
      attr_accessor :Queries, :SearchMode, :IncludeFacets, :FacetFilters, :Limiters, :Sort, :PublicationId,
                    :RelatedContent, :AutoSuggest, :Expanders, :AutoCorrect

      def initialize(options = {}, info)

        # defaults
        @SearchMode = info.default_search_mode
        @IncludeFacets = 'y'
        @Sort = 'relevance'
        @AutoSuggest = info.default_auto_suggest
        @AutoCorrect = info.default_auto_correct
        _has_query = false

        @Expanders = info.default_expander_ids
        _my_expanders = []
        _available_expander_ids = info.available_expander_ids

        @Limiters = nil
        _my_limiters = []

        @FacetFilters = []
        filter_id = 1

        @RelatedContent = info.default_related_content_types
        _my_related_content = []
        _available_related_content_types = info.available_related_content_types

        # blacklight year range slider input
        # "range"=>{"pub_year_tisim"=>{"begin"=>"1970", "end"=>"1980"}}
        if options.has_key?('range')
          if options['range'].has_key?('pub_year_tisim')
            begin_year = nil
            end_year = nil
            if options['range']['pub_year_tisim'].has_key?('begin')
              begin_year = options['range']['pub_year_tisim']['begin']
            end
            if options['range']['pub_year_tisim'].has_key?('end')
              end_year = options['range']['pub_year_tisim']['end']
            end
            unless begin_year.nil? or end_year.nil?
              pub_year_tisim_range = begin_year + '-01/' + end_year + '-01'
              _my_limiters.push({:Id => 'DT1', :Values => [pub_year_tisim_range]})
            end
          end
        end

        options.each do |key, value|

          case key

            # ====================================================================================
            # query
            # ====================================================================================
            when :query, 'q'

              match = value.match /((?<boolean_operator>AND|OR|NOT),)?((?<field_code>AU|SU|TI|TX|AB|SO|IS|IB|DE|SE|SH|KW):)?(?<term>.*)/

              _boolean_operator = match[:boolean_operator]

              # add blacklight search_fields
              _field_code = match[:field_code]
              if _field_code.nil? || options.has_key?('search_field')
                _field = options['search_field']
                case _field
                  when 'author'
                    _field_code = 'AU'
                  when 'subject'
                    _field_code = 'SU'
                  when 'title'
                    _field_code = 'TI'
                  when 'text'
                    _field_code = 'TX'
                  when 'abstract'
                    _field_code = 'AB'
                  when 'source'
                    _field_code = 'SO'
                  when 'issn'
                    _field_code = 'IS'
                  when 'isbn'
                    _field_code = 'IB'
                  when 'descriptor'
                    _field_code = 'DE'
                  when 'series'
                    _field_code = 'SE'
                  when 'subject_heading'
                    _field_code = 'SH'
                  when 'keywords'
                    _field_code = 'KW'
                  when /[A-Z]{2}/
                    _field_code = _field
                end
              end

              _term = match[:term]
              if _term.nil?
                _term = value
              end

              query = {}
              query.merge!({ :BooleanOperator => _boolean_operator }) unless _boolean_operator.nil?
              query.merge!({ :FieldCode => _field_code }) unless _field_code.nil?
              query.merge!({ :Term => _term }) unless _term.nil?

              @Queries =  [query]

              _has_query = true

            # ====================================================================================
            # mode
            # ====================================================================================
            when :mode
              if info.available_search_mode_types.include? value.downcase
                @SearchMode = value.downcase
              else
                @SearchMode = info.default_search_mode
              end

            # ====================================================================================
            # facets
            # ====================================================================================
            when :include_facets
              @IncludeFacets = value ? 'y' : 'n'

            when :facet_filters
              @FacetFilters = value

            # ====================================================================================
            # sort
            # ====================================================================================
            when :sort, 'sort'
              if info.available_sorts(value.downcase).empty?
                if value.downcase == 'newest' || value.downcase == 'pub_date_sort desc'
                  @Sort = 'date'
                elsif value.downcase == 'oldest' || value.downcase == 'pub_date_sort asc'
                  @Sort = 'date2'
                elsif value.downcase == 'score desc'
                  @Sort = 'relevance'
                else
                  @Sort = 'relevance'
                end
              else
                @Sort = value.downcase
              end

            # ====================================================================================
            # publication id
            # ====================================================================================
            when :publication_id
              @PublicationId = value

            # ====================================================================================
            # auto suggest & correct
            # ====================================================================================
            when :auto_suggest, 'auto_suggest'
              @AutoSuggest = value ? 'y' : 'n'

            when :auto_correct, 'auto_correct'
              @AutoCorrect = value ? 'y' : 'n'

            # ====================================================================================
            # expanders
            # ====================================================================================
            when :expanders
              value.each do |item|
                if _available_expander_ids.include? item.downcase
                  _my_expanders.push(item)
                end
              end
              if _my_expanders.empty?
                _my_expanders = info.default_expander_ids
              end
              @Expanders = _my_expanders

            # ====================================================================================
            # solr limiters & facets
            # ====================================================================================

            when 'f'
              _search_limiter_list = []
              if value.has_key?('eds_search_limiters_facet')
                _search_limiter_list = value['eds_search_limiters_facet']
              end
              info.available_limiters.each do |limiter|
                # only handle 'select' limiters (ones with values of 'y' or 'n')
                if ( _search_limiter_list.include? limiter['Label'] or _search_limiter_list.include? limiter['Id']) and limiter['Type'] == 'select'
                  _my_limiters.push({:Id => limiter['Id'], :Values => ['y']})
                end
              end

              # date limiters
              if value.has_key?('eds_publication_year_range_facet')
                _list = value['eds_publication_year_range_facet']
                _this_year = Date.today.year
                _this_month = Date.today.month
                _list.each do |item|
                  if item == 'This year'
                    _range = _this_year.to_s + '-01/' + _this_year.to_s + '-' + _this_month.to_s
                    _my_limiters.push({:Id => 'DT1', :Values => [_range]})
                  end
                  if item == 'Last 3 years'
                    _range = (_this_year-3).to_s + '-' + _this_month.to_s + '/' + _this_year.to_s + '-' + _this_month.to_s
                    _my_limiters.push({:Id => 'DT1', :Values => [_range]})
                  end
                  if item == 'Last 10 years'
                    _range = (_this_year-10).to_s + '-' + _this_month.to_s + '/' + _this_year.to_s + '-' + _this_month.to_s
                    _my_limiters.push({:Id => 'DT1', :Values => [_range]})
                  end
                  if item == 'Last 50 years'
                    _range = (_this_year-50).to_s + '-' + _this_month.to_s + '/' + _this_year.to_s + '-' + _this_month.to_s
                    _my_limiters.push({:Id => 'DT1', :Values => [_range]})
                  end
                  if item == 'More than 50 years ago'
                    _range = '0000-01/' + (_this_year-50).to_s + '-12'
                    _my_limiters.push({:Id => 'DT1', :Values => [_range]})
                  end
                end
              end

              # Language
              if value.has_key?('eds_language_facet')
                lang_list = value['eds_language_facet']
                lang_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'Language', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # SubjectEDS
              if value.has_key?('eds_subject_topic_facet')
                subj_list = value['eds_subject_topic_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'SubjectEDS', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # SubjectGeographic
              if value.has_key?('eds_subjects_geographic_facet')
                subj_list = value['eds_subjects_geographic_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'SubjectGeographic', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # Publisher
              if value.has_key?('eds_publisher_facet')
                subj_list = value['eds_publisher_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'Publisher', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # Journal
              if value.has_key?('eds_journal_facet')
                subj_list = value['eds_journal_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'Journal', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # Category
              if value.has_key?('eds_category_facet')
                subj_list = value['eds_category_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'Category', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # LocationLibrary
              if value.has_key?('eds_library_location_facet')
                subj_list = value['eds_library_location_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'LocationLibrary', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # CollectionLibrary
              if value.has_key?('eds_library_collection_facet')
                subj_list = value['eds_library_collection_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'CollectionLibrary', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # AuthorUniversity
              if value.has_key?('eds_author_university_facet')
                subj_list = value['eds_author_university_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'AuthorUniversity', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # PublicationYear
              if value.has_key?('eds_publication_year_facet')
                year_list = value['eds_publication_year_facet']
                year_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'PublicationYear', 'Value' => item}]})
                  filter_id += 1
                end
              end

              # Special Cases:

              # SourceType
              if value.has_key?('eds_publication_type_facet')
                f_list = value['eds_publication_type_facet']
                f_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'SourceType', 'Value' => item}]})
                  filter_id += 1
                end
              end
              # ContentProvider
              if value.has_key?('eds_content_provider_facet')
                subj_list = value['eds_content_provider_facet']
                subj_list.each do |item|
                  @FacetFilters.push({'FilterId' => filter_id, 'FacetValues' => [{'Id' => 'ContentProvider', 'Value' => item}]})
                  filter_id += 1
                end
              end

            # ====================================================================================
            # limiters
            # ====================================================================================

            when :limiters
              value.each do |item|
                _key = item.split(':',2).first.upcase
                _values = item.split(':',2).last
                # is limiter id available?
                if info.available_limiter_ids.include? _key
                  _limiter = info.available_limiters(_key)
                  # if multi-value, add the values if they're available
                  if _limiter['Type'] == 'multiselectvalue'
                    _available_values = info.available_limiter_values(_key)
                    _multi_values = []
                    _values.split(',').each do |val|
                      # todo: make case insensitive?
                      if _available_values.include? val
                        _multi_values.push(val)
                      end
                    end
                    if _multi_values.empty?
                      # do nothing, none of the values are available
                    else
                      _my_limiters.push({:Id => _key, :Values => _multi_values})
                    end
                    # single value, just pass it on
                  else
                    _my_limiters.push({:Id => _key, :Values => [_values]})
                  end
                end
              end
              @Limiters = _my_limiters

            # ====================================================================================
            # related content
            # ====================================================================================
            when :related_content
              value.each do |item|
                if _available_related_content_types.include? item.downcase
                  _available_related_content_types.push(item)
                else
                  # silently ignore
                end
              end
              if _my_related_content.empty?
                _my_related_content = info.default_related_content_types
              end
              @RelatedContent = _my_related_content

            # ====================================================================================
            # unsupported parameters, ignore
            # ====================================================================================
            else
              # ignore

          end

        end # end options parsing

        # set solr limiters, if any
        @Limiters = _my_limiters

      end

    end

    class RetrievalCriteria
      include JSONable
      attr_accessor :View, :ResultsPerPage, :PageNumber, :Highlight, :IncludeImageQuickView
      def initialize(options = {}, info)

        # defaults
        @View = info.default_result_list_view
        @IncludeImageQuickView = info.default_include_image_quick_view
        @ResultsPerPage = info.default_results_per_page
        @PageNumber = 1

        options.each do |key, value|

          case key

            # ====================================================================================
            # view
            # ====================================================================================
            when :view, 'view'
              if info.available_result_list_views.include? value.downcase
                @View = value.downcase
              else
                @View = info.default_result_list_view
              end

            # ====================================================================================
            # results per page
            # ====================================================================================
            when :results_per_page, 'results_per_page', 'rows', 'per_page'
              if value.to_i > info.max_results_per_page
                @ResultsPerPage = info.max_results_per_page
              else
                @ResultsPerPage = value.to_i
              end

            # ====================================================================================
            # page number
            # ====================================================================================
            when :page_number, 'page_number', 'page'
              @PageNumber = value.to_i
            # solr starts at page 0
            # when 'start'
            #  @PageNumber = value.to_i + 1

            # ====================================================================================
            # highlight
            # ====================================================================================
            when :highlight, 'highlight'
              @Highlight = value
            # solr/blacklight version
            when 'hl'
              if value == 'on'
                @Highlight = 'y'
              else
                @Highlight = 'y' # API bug: if set to 'n' you won't get research starter abstracts!
              end

            # ====================================================================================
            # image quick view
            # ====================================================================================
            when :include_image_quick_view, 'include_image_quick_view'
              @IncludeImageQuickView = value ? 'y' : 'n'

            else

          end

        end

      end
  
    end

  end
end
