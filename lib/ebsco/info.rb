require 'ebsco/options'

module EBSCO

  class Info

    attr_accessor :info, :criteria

    def initialize(info_raw)
      @info = info_raw
      @criteria = @info['AvailableSearchCriteria']
    end

    # ====================================================================================
    # SORTS
    # ====================================================================================

    def available_sorts (id = 'all')
      @criteria.fetch('AvailableSorts',{}).select{|item| item['Id'] == id || id == 'all'}
    end

    # ====================================================================================
    # SEARCH FIELDS
    # ====================================================================================

    def search_fields (code = 'all')
      @criteria.fetch('AvailableSearchFields',{}).select{|item| item['FieldCode'] == code || code == 'all'}
    end

    # ====================================================================================
    # SEARCH MODES
    # ====================================================================================

    def available_search_modes (mode = 'all_available')
      @criteria.fetch('AvailableSearchModes',{}).select{|item| item['Mode'] == mode || mode == 'all_available'}
    end

    def default_search_mode
      @criteria.fetch('AvailableSearchModes',{}).find{|item| item['DefaultOn'] == 'y'}['Mode']
    end

    # ====================================================================================
    # EXPANDERS
    # ====================================================================================

    def available_expander_ids
      @criteria.fetch('AvailableExpanders',{}).map{|hash| hash['Id']}
    end

    def default_expander_ids
      @criteria.fetch('AvailableExpanders',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Id']}
    end

    def available_expanders (id = 'all')
      if id == 'all'
        @criteria.fetch('AvailableExpanders',{})
      else
        @criteria.fetch('AvailableExpanders',{}).find{|item| item['Id'] == id}
      end
    end

    # ====================================================================================
    # LIMITERS
    # ====================================================================================

    def available_limiter_ids
      @criteria.fetch('AvailableLimiters',{}).map{|hash| hash['Id']}
    end

    def default_limiter_ids
      @criteria.fetch('AvailableLimiters',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Id']}
    end

    def available_limiters (id = 'all')
      if id == 'all'
        @criteria.fetch('AvailableLimiters',{})
      else
        @criteria.fetch('AvailableLimiters',{}).find{|item| item['Id'] == id}
      end
    end

    # get an array of limiter values for a Type=multiselectvalue limiter
    def available_limiter_values (id)
      _limiter = @criteria.fetch('AvailableLimiters',{}).find{|item| item['Id'] == id}
      if _limiter['Type'] == 'multiselectvalue'
        _limiter['LimiterValues'].map{|hash| hash['Value']}
      end
    end

    # ====================================================================================
    # RELATED CONTENT
    # ====================================================================================

    def available_related_content_types
      @criteria.fetch('AvailableRelatedContent',{}).map{|hash| hash['Type']}
    end

    def default_related_content_types
      @criteria.fetch('AvailableRelatedContent',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Type']}
    end

    def available_related_content (type = 'all')
      if type == 'all'
        @criteria.fetch('AvailableRelatedContent',{})
      else
        @criteria.fetch('AvailableRelatedContent',{}).find{|item| item['Type'] == type}
      end
    end

    # ====================================================================================
    # AUTO SUGGEST
    # ====================================================================================

    def did_you_mean (id = 'all')
      @criteria.fetch('AvailableDidYouMeanOptions',{}).select{|item| item['Id'] == id || id == 'all'}
    end

    def default_auto_suggest
      @criteria.fetch('AvailableDidYouMeanOptions',{}).find{|item| item['Id'] == 'AutoSuggest'}['DefaultOn']
    end

    # ====================================================================================
    # RESULTS VIEW SETTINGS
    # ====================================================================================

    def default_results_per_page
      @info['ViewResultSettings']['ResultsPerPage']
    end

    def max_results_per_page
      100
    end

    def available_result_list_views
      %w{brief title detailed}
    end

    def default_result_list_view
      @info['ViewResultSettings']['ResultListView']
    end

    def default_highlight
      true
    end

    # ====================================================================================
    # API SETTINGS
    # ====================================================================================

    def max_record_jump
      @info['ApiSettings']['MaxRecordJumpAhead']
    end

    # ====================================================================================
    # APPLICATION SETTINGS
    # ====================================================================================

    def session_timeout
      @info['ApplicationSettings']['SessionTimeout']
    end

    # ====================================================================================
    # AVAILABLE ACTIONS
    # ====================================================================================

    def available_actions
      @info.deep_find('AddAction')
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