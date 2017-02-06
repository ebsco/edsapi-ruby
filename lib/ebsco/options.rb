require 'ebsco/jsonable'

module EBSCO

  class Options
    include JSONable
    attr_accessor :SearchCriteria, :RetrievalCriteria, :Actions
    def initialize(options = {}, info)

      @SearchCriteria = EBSCO::SearchCriteria.new(options, info)

      @RetrievalCriteria = EBSCO::RetrievalCriteria.new(options, info)

      @Actions = []
      if options.has_key? :actions
        add_actions(options[:actions], info)
      end

    end

    def add_actions(actions, info)
      if actions.kind_of?(Array) && actions.count > 0
        actions.each do |item|
          if is_valid_action(item, info)
            @Actions.push item
          end
        end
      else
        if is_valid_action(actions, info)
           @Actions = [actions]
        end
      end
    end

    def is_valid_action(action, info)
      _available_actions = info.available_actions
      _available_value_actions = %w{PG4 CS1 FM FT FR RV DT1 SO}
      _value_action = _available_value_actions.any? { |type| action.include? type }
      _defined_action = _available_actions.include? action
      if _value_action || _defined_action
        true
      else
        false
      end
    end

  end

  class SearchCriteria
    include JSONable
    attr_accessor :Queries, :SearchMode, :IncludeFacets, :Limiters, :Sort, :PublicationId, :RelatedContent, :AutoSuggest, :Expanders
    def initialize(options = {}, info)

      # ====================================================================================
      # QUERY
      # ====================================================================================
      # if a query exists set it, otherwise raise error
      if options.key? :query
        @Queries =  [{:Term => options[:query]}]
      else
        raise InvalidParameterError, 'Required parameter: query is missing'
      end

      # ====================================================================================
      # SEARCH MODE
      # ====================================================================================
      # if mode is provided make sure it is available, otherwise use default
      if options.key? :mode
        if info.available_search_modes(options[:mode].downcase).empty?
          @SearchMode = info.default_search_mode
        else
          @SearchMode = options[:mode].downcase
        end
      else
        @SearchMode = info.default_search_mode
      end

      # ====================================================================================
      # INCLUDE FACETS
      # ====================================================================================
      # info has nothing to say about include facets, default is 'y'
      if options.key? :include_facets
        @IncludeFacets = options[:include_facts] ? 'y' : 'n'
      else
        @IncludeFacets = 'y'
      end

      # ====================================================================================
      # SORT
      # ====================================================================================
      # there is no default attribute for sort in info, default to 'relevance'
      # support some aliases for date and date2 ids
      if options.key? :sort
        if info.available_sorts(options[:sort].downcase).empty?
          if options[:sort].downcase == 'newest'
            @Sort = 'date'
          elsif options[:sort].downcase == 'oldest'
            @Sort = 'date2'
          else
            @Sort = 'relevance'
          end
        else
          @Sort = options[:sort].downcase
        end
      else
        @Sort = 'relevance'
      end

      # ====================================================================================
      # PUBLICATION ID
      # ====================================================================================
      if options.key? :publication_id
        # way to validate input? check if profile is configured for it?
        @PublicationId = options[:publication_id]
      end

      # ====================================================================================
      # AUTO SUGGEST
      # ====================================================================================
      # possible for auto_suggest to not be available?

      if options.key? :auto_suggest
        @AutoSuggest = options[:auto_suggest] ? 'y' : 'n'
      else
        if info.did_you_mean('AutoSuggest').empty?
          @AutoSuggest = 'n'
        else
          @AutoSuggest = info.default_auto_suggest
        end
      end

      # ====================================================================================
      # EXPANDERS
      # ====================================================================================
      _my_expanders = []
      _available_expander_ids = info.available_expander_ids
      if options.key? :expanders
        options[:expanders].each do |item|
          if _available_expander_ids.include? item.downcase
            _my_expanders.push(item)
          end
        end
        if _my_expanders.empty?
          _my_expanders = info.default_expander_ids
        end
      else
        _my_expanders = info.default_expander_ids
      end
      if _my_expanders.empty?
        @Expanders = nil
      else
        @Expanders = _my_expanders
      end

      # ====================================================================================
      # LIMITERS
      # ====================================================================================
      # Example: ['FT:y','LA99:English,French,German']
      _my_limiters = []
      if options.key? :limiters
        options[:limiters].each do |item|
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
      end

      if _my_limiters.empty?
        @Limiter = nil
      else
        @Limiters = _my_limiters
      end

      # ====================================================================================
      # RELATED CONTENT
      # ====================================================================================
      # Example: [rs,emp] for research starters and exact match publications
      _my_related_content = []
      _available_related_content_types = info.available_related_content_types
      if options.key? :related_content
        options[:related_content].each do |item|
          # split on commas?
          if _available_related_content_types.include? item.downcase
            _available_related_content_types.push(item)
          end
        end
        if _my_related_content.empty?
          _my_related_content = info.default_related_content_types
        end
      else
        _my_related_content = info.default_related_content_types
      end
      if _my_related_content.empty?
        @RelatedContent = nil
      else
        @RelatedContent = _my_related_content
      end
    end
  end

  class RetrievalCriteria
    include JSONable
    attr_accessor :View, :ResultsPerPage, :PageNumber, :Highlight
    def initialize(options = {}, info)

      # ====================================================================================
      # RESULT LIST VIEW
      # ====================================================================================
      if options.key? :view
        if info.available_result_list_views.include? options[:view].downcase
          @View = options[:view].downcase
        else
          @View = info.default_result_list_view
        end
      else
        @View = info.default_result_list_view
      end

      # ====================================================================================
      # RESULTS PER PAGE
      # ====================================================================================
      if options.key? :results_per_page
        if options[:results_per_page] > 100
          @ResultsPerPage = info.max_results_per_page
        else
          @ResultsPerPage = options[:results_per_page]
        end
      else
        @ResultsPerPage = info.default_results_per_page
      end

      # ====================================================================================
      # PAGE NUMBER
      # ====================================================================================
      if options.key? :page_number
        @PageNumber = options[:page_number]
      else
        @PageNumber = 1
      end

      # ====================================================================================
      # HIGHLIGHT
      # ====================================================================================
      if options.key? :highlight
        @Highlight = options[:highlight] ? 'y' : 'n'
      else
        @Highlight = info.default_highlight ? 'y' : 'n'
      end

    end

  end

     # todo: reimplement this logic
      # # temporary fix while API SI resolves
      # # catches case where user navigates past result page 250 and applies facet/limiter
      # if (options.index('&action=') && (options.index('&action=') > 0))
      #   if (options.index('&action=GoToPage(').nil? && options.index('&action=SetView(').nil?)
      #     if (options.index('&pagenumber=') && (options.index('&pagenumber=') > 0))
      #       beginSubstring = options.index('&pagenumber=') + 12
      #       currentpage = options[beginSubstring..-1]
      #       newOptions = options[0..beginSubstring-1]
      #       endSubstring = currentpage.index('&') - 1
      #       newOptionsEnd = currentpage[endSubstring+1..-1]
      #       options = newOptions + "1" + newOptionsEnd
      #     end
      #   end
      # end


end