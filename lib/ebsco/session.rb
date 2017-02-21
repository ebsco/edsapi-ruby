require 'ebsco/version'
require 'ebsco/info'
require 'ebsco/results'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'json'

module EBSCO

  class Session

    attr_accessor :auth_token, :session_token, :info, :search_options
    attr_writer :user_id, :password, :guest, :profile

    def initialize(options = {})
      
      if options.has_key? :user_id
        @user_id = options[:user_id]
      elsif ENV.has_key? 'EDS_USER'
        @user_id = ENV['EDS_USER']
      end

      if options.has_key? :password
        @password = options[:password]
      elsif ENV.has_key? 'EDS_PASS'
        @password = ENV['EDS_PASS']
      end

      if options.has_key? :profile
        @profile = options[:profile]
      elsif ENV.has_key? 'EDS_PROFILE'
        @profile = ENV['EDS_PROFILE']
      end
      raise EBSCO::InvalidParameter, 'Session must specify a valid api profile.' if blank?(@profile)

      if options.has_key? :guest
        @guest = options[:guest] ? 'y' : 'n'
      elsif ENV.has_key? 'EDS_GUEST'
        @guest = ENV['EDS_GUEST']
      end

      if options.has_key? :org
        @org = options[:org]
      elsif ENV.has_key? 'EDS_ORG'
        @org = ENV['EDS_ORG']
      end

      if options.has_key? :auth
        @auth_type = options[:auth]
      elsif ENV.has_key? 'EDS_AUTH'
        @auth_type = ENV['EDS_AUTH']
      else
        @auth_type = 'user'
      end

      @max_retries = MAX_ATTEMPTS
      @auth_token = create_auth_token
      @session_token = create_session_token
      @info = EBSCO::Info.new(do_request(:get, path: INFO_URL))
      @current_page = 0

    end

    def end
      # todo: catch when there is no valid session?
      do_request(:post, path: END_SESSION_URL, payload: {:SessionToken => @session_token})
      connection.headers['x-sessionToken'] = ''
      @session_token = ''
    end

    # ====================================================================================
    # SEARCH, QUERY, RETRIEVE
    # ====================================================================================

    def search(options = {}, add_actions = false)

      # create/recreate the search options if nil or not passing actions
      if @search_options.nil? || !add_actions
        @search_options = EBSCO::Options.new(options, @info)
      end
      #puts JSON.pretty_generate(@search_options)
      _response = do_request(:post, path: SEARCH_URL, payload: @search_options)
      @search_results = EBSCO::Results.new(_response)
      @current_page = @search_results.page_number
      @search_results
    end

    def simple_search(query)
      search({:query => query})
    end

    def retrieve(dbid:, an:, highlight: nil, ebook: 'ebook-pdf')
      payload = {:DbId => dbid, :An => an, :HighlighTerms => highlight, :EbookPreferredFormat =>  ebook}
      retrieve_response = do_request(:post, path: RETRIEVE_URL, payload: payload)
      EBSCO::Record.new(retrieve_response)
    end

    # Clear all specified query expressions, facet filters, limiters and expanders, and set the page number back to 1.
    def clear_search
      add_actions 'ClearSearch()'
    end

    # Clears all queries and facet filters, and set the page number back to 1; limiters and expanders are not modified.
    def clear_queries
      add_actions 'ClearQueries()'
    end

    # Add a query to the search request. When a query is added, it will be assigned an ordinal, which will be exposed
    # in the search response message. It also removes any specified facet filters and sets the page number to 1.
    def add_query(query)
      add_actions "AddQuery(#{query})"
    end

    # Removes query from the currently specified search. It also removes any specified facet filters and sets the
    # page number to 1.
    def remove_query(query_id)
      add_actions "removequery(#{query_id})"
    end

    # Sets the sort for the search. The available sorts for the specified databases can be obtained from the API’s
    # INFO method (Please see related documentation.) Sets the page number back to 1.
    def set_sort(val)
      add_actions "SetSort(#{val})"
    end

    # Sets the search mode. The available search modes are returned from the info method.
    def set_search_mode(mode)
      add_actions "SetSearchMode(#{mode})"
    end

    # Specifies the view parameter. The view representes the amount of data to return with the search.
    def set_view(view)
      add_actions "SetView(#{view})"
    end

    # Sets whether or not to turn highlighting on or off (y|n).
    def set_highlight(val)
      add_actions "SetHighlight(#{val})"
    end

    # Sets the page size on the search request.
    def results_per_page(num)
      add_actions "SetResultsPerPage(#{num})"
    end

    # A related content type to additionally search for and include with the search results.
    def include_related_content(val)
      add_actions "includerelatedcontent(#{val})"
    end

    # ====================================================================================
    # PAGINATION
    # ====================================================================================

    def next_page
      page = @current_page + 1
      get_page(page)
    end

    def prev_page
      get_page([1, @current_page - 1].sort.last)
    end

    # Sets the page number on the search request.
    def get_page(page = 1)
      add_actions "GoToPage(#{page})"
    end

    # Increments the current page number by the value specified. If the current page was 5 and the specified value
    # was 2, the page number would be set to 7.
    def move_page(num)
      add_actions "MovePage(#{num})"
    end

    # Sets the page number back to 1.
    def reset_page
      add_actions 'ResetPaging()'
    end

    # ====================================================================================
    # FACETS
    # ====================================================================================

    # 'y' or 'n'
    def set_include_facets(val)
      add_actions "SetIncludeFacets(#{val})"
    end

    def clear_facets
      add_actions 'ClearFacetFilters()'
    end

    def add_facet(facet_id, facet_val)
      add_actions "AddFacetFilter(#{facet_id}:#{facet_val})"
    end

    def remove_facet(group_id)
      add_actions "RemoveFacetFilter(#{group_id})"
    end

    def remove_facet_value(group_id, facet_id, facet_val)
      add_actions "RemoveFacetFilterValue(#{group_id},#{facet_id}:#{facet_val})"
    end

    # ====================================================================================
    # LIMITERS
    # ====================================================================================

    def clear_limiters
      add_actions 'ClearLimiters()'
    end

    def add_limiter(id, val)
      add_actions "AddLimiter(#{id}:#{val})"
    end

    def remove_limiter(id)
      add_actions "RemoveLimiter(#{id})"
    end

    def remove_limiter_value(id, val)
      add_actions "RemoveLimiterValue(#{id}:#{val})"
    end

    # ====================================================================================
    # EXPANDERS
    # ====================================================================================

    def clear_expanders
      add_actions 'ClearExpanders()'
    end

    def add_expander(val)
      add_actions "AddExpander(#{val})"
    end

    def remove_expander(val)
      add_actions "RemoveExpander(#{val})"
    end

    # ====================================================================================
    # PUBLICATION (this is only used for profiles configured for publication searching)
    # ====================================================================================

    def add_publication(pub_id)
      add_actions "AddPublication(#{pub_id})"
    end

    def remove_publication(pub_id)
      add_actions "RemovePublication(#{pub_id})"
    end

    def remove_all_publications
      add_actions 'RemovePublication()'
    end

    # ====================================================================================
    # INTERNAL METHODS
    # ====================================================================================

    # add actions to an existing search session
    def add_actions(actions)
      # todo: create search options if nil?
      search(@search_options.add_actions(actions, @info), true)
    end

    def do_request(method, path:, payload: nil, attempt: 0)

      if attempt > MAX_ATTEMPTS
        raise EBSCO::ApiError, 'EBSCO API error: Multiple attempts to perform request failed.'
      end

      begin
        resp = connection.send(method) do |req|
          case method
            when :get
              req.url path
            when :post
              req.url path
              req.body = JSON.generate(payload)
            else
              raise EBSCO::ApiError, "EBSCO API error: Method #{method} not supported for endpoint #{path}"
          end
        end
        resp.body
      rescue Exception => e
        if e.respond_to? 'fault'
          error_code = e.fault[:error_body]['ErrorNumber'] || e.fault[:error_body]['ErrorCode']
          if not error_code.nil?
            case error_code
              # session token missing
              when '108', '109'
                @session_token = create_session_token
                do_request(method, path: path, payload: payload, attempt: attempt+1)
              # auth token invalid
              when '104', '107'
                @auth_token = create_auth_token
                do_request(method, path: path, payload: payload, attempt: attempt+1)
              else
                raise e
            end
          end
        else
          raise e
        end
      end
    end

    # attempts to query profile capabilities
    # dummy search just to get the list of available databases
    def get_available_databases
      search({query: 'supercalifragilisticexpialidocious-supercalifragilisticexpialidocious',
              results_per_page: 1,
              mode: 'all',
              include_facets: false}).database_stats
    end

    def get_available_database_ids
      get_available_databases.map{|item| item[:id]}
    end

    def dbid_in_profile(dbid)
      get_available_database_ids.include? dbid
    end

    def publication_match_in_profile
      @info.available_related_content_types.include? 'emp'
    end

    def research_starters_match_in_profile
      @info.available_related_content_types.include? 'rs'
    end

    private

    def connection
      Faraday.new(url: EDS_API_BASE) do |faraday|
        faraday.headers['Content-Type'] = 'application/json;charset=UTF-8'
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['x-sessionToken'] = @session_token ? @session_token : ''
        faraday.headers['x-authenticationToken'] = @auth_token ? @auth_token : ''
        faraday.headers['User-Agent'] = USER_AGENT
        faraday.request :url_encoded
        faraday.use FaradayMiddleware::RaiseHttpException
        faraday.response :json, :content_type => /\bjson$/
        #faraday.response :logger, Logger.new(LOG)
        faraday.adapter Faraday.default_adapter
      end
    end

    def create_auth_token
      if @auth_token.nil?
        # ip auth
        if (blank?(@user_id) && blank?(@password)) || @auth_type.casecmp('ip') == 0
          _response = do_request(:post, path: IP_AUTH_URL)
        # user auth
        else
          _response = do_request(:post, path: UID_AUTH_URL, payload: {:UserId => @user_id, :Password => @password})
          @auth_token = _response['AuthToken']
       end
      end
      @auth_token
    end

    def create_session_token
      _response = do_request(:post, path: CREATE_SESSION_URL, payload: {:Profile => @profile, :Guest => @guest})
      @session_token = _response['SessionToken']
    end

    # helper methods

    def blank?(var)
      var.nil? || var.respond_to?(:length) && var.length == 0
    end

  end

end