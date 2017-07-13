require 'ebsco/eds/options'

module EBSCO

  module EDS
    class Info

      attr_accessor :available_search_criteria, :view_result_settings, :application_settings, :api_settings

      def initialize(info, config = {})
        @results_per_page = config[:max_results_per_page] ? config[:max_results_per_page] : 100
        @available_search_criteria = info['AvailableSearchCriteria']
        @view_result_settings = info['ViewResultSettings']
        @application_settings = info['ApplicationSettings']
        @api_settings = info['ApiSettings']
      end

      # ====================================================================================
      # SORTS
      # ====================================================================================

      def available_sorts (id = 'all')
        @available_search_criteria.fetch('AvailableSorts',{}).select{|item| item['Id'] == id || id == 'all'}
      end

      # ====================================================================================
      # SEARCH FIELDS
      # ====================================================================================

      def search_fields (code = 'all')
        @available_search_criteria.fetch('AvailableSearchFields',{}).select{|item| item['FieldCode'] == code || code == 'all'}
      end

      # ====================================================================================
      # SEARCH MODES
      # ====================================================================================

      def available_search_modes (mode = 'all_available')
        @available_search_criteria.fetch('AvailableSearchModes',{}).select{|item| item['Mode'] == mode || mode == 'all_available'}
      end

      def available_search_mode_types
        available_search_modes.map{|hash| hash['Mode']}
      end

      def default_search_mode
        @available_search_criteria.fetch('AvailableSearchModes',{}).find{|item| item['DefaultOn'] == 'y'}['Mode']
      end

      # ====================================================================================
      # EXPANDERS
      # ====================================================================================

      def available_expander_ids
        @available_search_criteria.fetch('AvailableExpanders',{}).map{|hash| hash['Id']}
      end

      def default_expander_ids
        @available_search_criteria.fetch('AvailableExpanders',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Id']}
      end

      def available_expanders (id = 'all')
        if id == 'all'
          @available_search_criteria.fetch('AvailableExpanders',{})
        else
          @available_search_criteria.fetch('AvailableExpanders',{}).find{|item| item['Id'] == id}
        end
      end

      # ====================================================================================
      # LIMITERS
      # ====================================================================================

      def available_limiter_ids
        @available_search_criteria.fetch('AvailableLimiters',{}).map{|hash| hash['Id']}
      end

      def default_limiter_ids
        @available_search_criteria.fetch('AvailableLimiters',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Id']}
      end

      def default_limiter_labels
        @available_search_criteria.fetch('AvailableLimiters',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Label']}
      end

      def available_limiters (id = 'all')
        if id == 'all'
          @available_search_criteria.fetch('AvailableLimiters',{})
        else
          @available_search_criteria.fetch('AvailableLimiters',{}).find{|item| item['Id'] == id}
        end
      end

      def available_limiter_labels
        @available_search_criteria.fetch('AvailableLimiters',{}).map{|hash| hash['Label']}
      end

      # get an array of limiter values for a Type=multiselectvalue limiter
      def available_limiter_values (id)
        _limiter = @available_search_criteria.fetch('AvailableLimiters',{}).find{|item| item['Id'] == id}
        if _limiter['Type'] == 'multiselectvalue'
          _limiter['LimiterValues'].map{|hash| hash['Value']}
        end
      end

      def get_limiter_by_label (label)
        @available_search_criteria.fetch('AvailableLimiters',{}).find{|item| item['Label'] == label}
      end

      # ====================================================================================
      # RELATED CONTENT
      # ====================================================================================

      def available_related_content_types
        available_related_content.map{|hash| hash['Type'] }
      end

      def default_related_content_types
        @available_search_criteria.fetch('AvailableRelatedContent',{}).select{|item| item['DefaultOn'] == 'y'}.map{|hash| hash['Type']}
      end

      def available_related_content (type = 'all')
        if type == 'all'
          @available_search_criteria.fetch('AvailableRelatedContent',{})
        else
          @available_search_criteria.fetch('AvailableRelatedContent',{}).find{|item| item['Type'] == type}
        end
      end

      # ====================================================================================
      # AUTO SUGGEST
      # ====================================================================================

      def did_you_mean (id = 'all')
        @available_search_criteria.fetch('AvailableDidYouMeanOptions',{}).select{|item| item['Id'] == id || id == 'all'}
      end

      def default_auto_suggest
        @available_search_criteria.fetch('AvailableDidYouMeanOptions',{}).find{|item| item['Id'] == 'AutoSuggest'}['DefaultOn']
      end

      # ====================================================================================
      # RESULTS VIEW SETTINGS
      # ====================================================================================

      def default_results_per_page
        @view_result_settings['ResultsPerPage']
      end

      def max_results_per_page
        @results_per_page
      end

      def available_result_list_views
        %w{brief title detailed}
      end

      def default_result_list_view
        @view_result_settings['ResultListView']
      end

      def default_highlight
        true
      end

      # ====================================================================================
      # API SETTINGS
      # ====================================================================================

      def max_record_jump
        @api_settings['MaxRecordJumpAhead']
      end

      # ====================================================================================
      # APPLICATION SETTINGS
      # ====================================================================================

      def session_timeout
        @application_settings['SessionTimeout']
      end

      # ====================================================================================
      # AVAILABLE ACTIONS
      # ====================================================================================

      def available_actions
        @available_search_criteria.deep_find_results('AddAction')
      end

    end

  end
end

# monkey patch
class Hash
  def deep_find_results(key, object=self, found=[])
    if object.respond_to?(:key?) && object.key?(key)
      found << object[key]
    end
    if object.is_a? Enumerable
      found << object.collect { |*a| deep_find(key, a.last) }
    end
    found.flatten.compact
  end
end