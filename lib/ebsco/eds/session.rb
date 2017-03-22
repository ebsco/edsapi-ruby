require 'ebsco/eds/version'
require 'ebsco/eds/info'
require 'ebsco/eds/results'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'json'

module EBSCO

  module EDS

    # Sessions are used to query and retrieve information from the EDS API.
    class Session

      # Contains search Info available in the session profile. Includes the sort options, search fields, limiters and expanders available to the profile.
      attr_accessor :info
      # Contains the search Options sent as part of each request to the EDS API such as limiters, expanders, search modes, sort order, etc.
      attr_accessor :search_options
      # The authentication token. This is passed along in the x-authenticationToken HTTP header.
      attr_accessor :auth_token # :nodoc:
      # The session token. This is passed along in the x-sessionToken HTTP header.
      attr_accessor :session_token # :nodoc:

      # Creates a new session.
      #
      # This can be done in one of two ways:
      #
      # === 1. Environment variables
      # * +EDS_AUTH+ - authentication method: 'ip' or 'user'
      # * +EDS_PROFILE+ - profile ID for the EDS API
      # * +EDS_USER+ - user id attached to the profile
      # * +EDS_PASS+ - user password
      # * +EDS_GUEST+ - allow guest access: 'y' or 'n'
      # * +EDS_ORG+ - name of your institution or company
      #
      # ==== Example
      # Once you have environment variables set, simply create a session like this:
      #   session = EBSCO::EDS::Session.new
      #
      # ===  2. \Options
      # * +:auth+
      # * +:profile+
      # * +:user+
      # * +:pass+
      # * +:guest+
      # * +:org+
      #
      # ==== Example
      #   session = EBSCO::EDS::Session.new {
      #     :auth => 'user',
      #     :profile => 'edsapi',
      #     :user => 'joe'
      #     :pass => 'secret',
      #     :guest => false,
      #     :org => 'Acme University'
      #   }
      def initialize(options = {})

        @session_token = ''
        @auth_token = ''

        if options.has_key? :user
          @user = options[:user]
        elsif ENV.has_key? 'EDS_USER'
          @user = ENV['EDS_USER']
        end

        if options.has_key? :pass
          @pass = options[:pass]
        elsif ENV.has_key? 'EDS_PASS'
          @pass = ENV['EDS_PASS']
        end

        if options.has_key? :profile
          @profile = options[:profile]
        elsif ENV.has_key? 'EDS_PROFILE'
          @profile = ENV['EDS_PROFILE']
        end
        raise EBSCO::EDS::InvalidParameter, 'Session must specify a valid api profile.' if blank?(@profile)

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

        if options.has_key? :auth_token
          @auth_token = options[:auth_token]
        else
          @auth_token = create_auth_token
        end

        if options.has_key? :session_token
          @session_token = options[:session_token]
        else
          @session_token = create_session_token
        end

        @info = EBSCO::EDS::Info.new(do_request(:get, path: INFO_URL))
        @current_page = 0
        @search_options = nil

      end

      # :category: Search & Retrieve Methods
      # Performs a search.
      #
      # Returns search Results.
      #
      # ==== \Options
      #
      # * +:query+ - Required. The search terms. Format: {booleanOperator},{fieldCode}:{term}. Example: SU:Hiking
      # * +:mode+ - Search mode to be used. Either: all (default), any, bool, smart
      # * +:results_per_page+ - The number of records retrieved with the search results (between 1-100, default is 20).
      # * +:page+ - Starting page number for the result set returned from a search (if results per page = 10, and page number = 3 , this implies: I am expecting 10 records starting at page 3).
      # * +:sort+ - The sort order for the search results. Either: relevance (default), oldest, newest
      # * +:highlight+ - Specifies whether or not the search term is highlighted using <highlight /> tags. Either true or false.
      # * +:include_facets+ - Specifies whether or not the search term is highlighted using <highlight /> tags. Either true (default) or false.
      # * +:facet_filters+ - Facets to apply to the search. Facets are used to refine previous search results. Format: \{filterID},{facetID}:{value}[,{facetID}:{value}]* Example: 1,SubjectEDS:food,SubjectEDS:fiction
      # * +:view+ - Specifies the amount of data to return with the response. Either 'title': title only; 'brief' (default): Title + Source, Subjects; 'detailed': Brief + full abstract
      # * +:actions+ - Actions to take on the existing query specification. Example: addfacetfilter(SubjectGeographic:massachusetts)
      # * +:limiters+ - Criteria to limit the search results by. Example: LA99:English,French,German
      # * +:expanders+ - Expanders that can be applied to the search. Either: thesaurus, fulltext, relatedsubjects
      # * +:publication_id+ - Publication to search within.
      # * +:related_content+ - Comma separated list of related content types to return with the search results. Either 'rs' (Research Starters) or 'emp' (Exact Publication Match)
      # * +:auto_suggest+ - Specifies whether or not to return search suggestions along with the search results. Either true or false (default).
      #
      # ==== Examples
      #
      #   results = session.search({query: 'abraham lincoln', results_per_page: 5, related_content: ['rs','emp']})
      #   results = session.search({query: 'volcano', results_per_page: 1, publication_id: 'eric', include_facets: false})
      def search(options = {}, add_actions = false)

        # create/recreate the search options if nil or not passing actions
        if @search_options.nil? || !add_actions
          @search_options = EBSCO::EDS::Options.new(options, @info)
        end
        #puts JSON.pretty_generate(@search_options)
        _response = do_request(:post, path: SEARCH_URL, payload: @search_options)
        @search_results = EBSCO::EDS::Results.new(_response, @info.available_limiters)
        @current_page = @search_results.page_number
        @search_results
      end

      # :category: Search & Retrieve Methods
      # Performs a simple search. All other search options assume default values.
      #
      # Returns search Results.
      #
      # ==== Attributes
      #
      # * +query+ - the search query.
      #
      # ==== Examples
      #
      #   results = session.simple_search('volcanoes')
      #
      def simple_search(query)
        search({:query => query})
      end

      # :category: Search & Retrieve Methods
      # Returns a Record based a particular result based on a database ID and accession number.
      #
      # ==== Attributes
      #
      # * +:dbid+ - The database ID (required).
      # * +:an+ - The accession number (required).
      # * +highlight+ - Comma separated list of terms to highlight in the data records (optional).
      # * +ebook+ - Preferred format to return ebook content in. Either ebook-pdf (default) or ebook-pdf.
      #
      # ==== Examples
      #   record = session.retrieve({dbid: 'asn', an: '108974507'})
      #
      def retrieve(dbid:, an:, highlight: nil, ebook: 'ebook-pdf')
        payload = {:DbId => dbid, :An => an, :HighlightTerms => highlight, :EbookPreferredFormat =>  ebook}
        retrieve_response = do_request(:post, path: RETRIEVE_URL, payload: payload)
        EBSCO::EDS::Record.new(retrieve_response)
      end

      # :category: Search & Retrieve Methods
      # Invalidates the session token. End Session should be called when you know a user has logged out.
      def end
        # todo: catch when there is no valid session?
        do_request(:post, path: END_SESSION_URL, payload: {:SessionToken => @session_token})
        connection.headers['x-sessionToken'] = ''
        @session_token = ''
      end

      # :category: Search & Retrieve Methods
      # Clear all specified query expressions, facet filters, limiters and expanders, and set the page number back to 1.
      # Returns search Results.
      def clear_search
        add_actions 'ClearSearch()'
      end

      # :category: Search & Retrieve Methods
      # Clears all queries and facet filters, and set the page number back to 1; limiters and expanders are not modified.
      # Returns search Results.
      def clear_queries
        add_actions 'ClearQueries()'
      end

      # :category: Search & Retrieve Methods
      # Add a query to the search request. When a query is added, it will be assigned an ordinal, which will be exposed
      # in the search response message. It also removes any specified facet filters and sets the page number to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.add_query('AND,California')
      def add_query(query)
        add_actions "AddQuery(#{query})"
      end

      # :category: Search & Retrieve Methods
      # Removes query from the currently specified search. It also removes any specified facet filters and sets the
      # page number to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.remove_query(1)
      def remove_query(query_id)
        add_actions "removequery(#{query_id})"
      end

      # :category: Search & Retrieve Methods
      # Add actions to an existing search session
      # Returns search Results.
      # ==== Examples
      #   results = session.add_actions('addfacetfilter(SubjectGeographic:massachusetts)')
      def add_actions(actions)
        # todo: create search options if nil?
        search(@search_options.add_actions(actions, @info), true)
      end

      # :category: Setter Methods
      # Sets the sort for the search. The available sorts for the specified databases can be obtained from the session’s
      # info attribute. Sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.set_sort('newest')
      def set_sort(val)
        add_actions "SetSort(#{val})"
      end

      # :category: Setter Methods
      # Sets the search mode. The available search modes are returned from the info method.
      # Returns search Results.
      # ==== Examples
      #   results = session.set_search_mode('bool')
      def set_search_mode(mode)
        add_actions "SetSearchMode(#{mode})"
      end

      # :category: Setter Methods
      # Specifies the view parameter. The view representes the amount of data to return with the search.
      # Returns search Results.
      # ==== Examples
      #   results = session.set_view('detailed')
      def set_view(view)
        add_actions "SetView(#{view})"
      end

      # :category: Setter Methods
      # Sets whether or not to turn highlighting on or off (y|n).
      # Returns search Results.
      # ==== Examples
      #   results = session.set_highlight('n')
      def set_highlight(val)
        add_actions "SetHighlight(#{val})"
      end

      # :category: Setter Methods
      # Sets the page size on the search request.
      # Returns search Results.
      # ==== Examples
      #   results = session.results_per_page(50)
      def results_per_page(num)
        add_actions "SetResultsPerPage(#{num})"
      end

      # :category: Setter Methods
      # A related content type to additionally search for and include with the search results.
      # Returns search Results.
      # ==== Examples
      #   results = session.include_related_content('rs')
      def include_related_content(val)
        add_actions "includerelatedcontent(#{val})"
      end

      # :category: Setter Methods
      # Specify to include facets in the results or not. Either 'y' or 'n'.
      # Returns search Results.
      # ==== Examples
      #   results = session.set_include_facets('n')
      def set_include_facets(val)
        add_actions "SetIncludeFacets(#{val})"
      end

      # --
      # ====================================================================================
      # PAGINATION
      # ====================================================================================
      # ++

      # :category: Pagination Methods
      # Get the next page of results.
      # Returns search Results.
      def next_page
        page = @current_page + 1
        get_page(page)
      end

      # :category: Pagination Methods
      # Get the previous page of results.
      # Returns search Results.
      def prev_page
        get_page([1, @current_page - 1].sort.last)
      end

      # :category: Pagination Methods
      # Get a specified page of results
      # Returns search Results.
      def get_page(page = 1)
        add_actions "GoToPage(#{page})"
      end

      # :category: Pagination Methods
      # Increments the current results page number by the value specified. If the current page was 5 and the specified value
      # was 2, the page number would be set to 7.
      # Returns search Results.
      def move_page(num)
        add_actions "MovePage(#{num})"
      end

      # :category: Pagination Methods
      # Get the first page of results.
      # Returns search Results.
      def reset_page
        add_actions 'ResetPaging()'
      end

      # --
      # ====================================================================================
      # FACETS
      # ====================================================================================
      # ++

      # :category: Facet Methods
      # Removes all specified facet filters. Sets the page number back to 1.
      # Returns search Results.
      def clear_facets
        add_actions 'ClearFacetFilters()'
      end

      # :category: Facet Methods
      # Adds a facet filter to the search request. Sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.add_facet('Publisher', 'wiley-blackwell')
      #   results = session.add_facet('SubjectEDS', 'water quality')
      #
      def add_facet(facet_id, facet_val)
        add_actions "AddFacetFilter(#{facet_id}:#{facet_val})"
      end

      # :category: Facet Methods
      # Removes a specified facet filter id. Sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.remove_facet(45)
      def remove_facet(group_id)
        add_actions "RemoveFacetFilter(#{group_id})"
      end

      # :category: Facet Methods
      # Removes a specific facet filter value from a group. Sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.remove_facet_value(2, 'DE', 'Psychology')
      def remove_facet_value(group_id, facet_id, facet_val)
        add_actions "RemoveFacetFilterValue(#{group_id},#{facet_id}:#{facet_val})"
      end

      # --
      # ====================================================================================
      # LIMITERS
      # ====================================================================================
      # ++

      # :category: Limiter Methods
      # Clears all currently specified limiters and sets the page number back to 1.
      # Returns search Results.
      def clear_limiters
        add_actions 'ClearLimiters()'
      end

      # :category: Limiter Methods
      # Adds a limiter to the currently defined search and sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.add_limiter('FT','y')
      def add_limiter(id, val)
        add_actions "AddLimiter(#{id}:#{val})"
      end

      # :category: Limiter Methods
      # Removes the specified limiter and sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.remove_limiter('FT')
      def remove_limiter(id)
        add_actions "RemoveLimiter(#{id})"
      end

      # :category: Limiter Methods
      # Removes a specified limiter value and sets the page number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.remove_limiter_value('LA99','French')
      def remove_limiter_value(id, val)
        add_actions "RemoveLimiterValue(#{id}:#{val})"
      end

      # --
      # ====================================================================================
      # EXPANDERS
      # ====================================================================================
      # ++

      # :category: Expander Methods
      # Removes all specified expanders and sets the page number back to 1.
      # Returns search Results.
      def clear_expanders
        add_actions 'ClearExpanders()'
      end

      # :category: Expander Methods
      # Adds expanders and sets the page number back to 1. Multiple expanders should be comma separated.
      # Returns search Results.
      # ==== Examples
      #   results = session.add_expander('thesaurus,fulltext')
      def add_expander(val)
        add_actions "AddExpander(#{val})"
      end

      # :category: Expander Methods
      # Removes a specified expander. Sets the page number to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.remove_expander('fulltext')
      def remove_expander(val)
        add_actions "RemoveExpander(#{val})"
      end

      # --
      # ====================================================================================
      # PUBLICATION (this is only used for profiles configured for publication searching)
      # ====================================================================================
      # ++

      # :category: Publication Methods
      # Specifies a publication to search within. Sets the pages number back to 1.
      # Returns search Results.
      # ==== Examples
      #   results = session.add_publication('eric')
      def add_publication(pub_id)
        add_actions "AddPublication(#{pub_id})"
      end

      # :category: Publication Methods
      # Removes a publication from the search. Sets the page number back to 1.
      # Returns search Results.
      def remove_publication(pub_id)
        add_actions "RemovePublication(#{pub_id})"
      end

      # :category: Publication Methods
      # Removes all publications from the search. Sets the page number back to 1.
      # Returns search Results.
      def remove_all_publications
        add_actions 'RemovePublication()'
      end

      # --
      # ====================================================================================
      # INTERNAL METHODS
      # ====================================================================================
      # ++

      def do_request(method, path:, payload: nil, attempt: 0) # :nodoc:

        if attempt > MAX_ATTEMPTS
          raise EBSCO::EDS::ApiError, 'EBSCO API error: Multiple attempts to perform request failed.'
        end

        begin
          resp = connection.send(method) do |req|
            case method
              when :get
                req.url path
              when :post
                req.url path
                unless payload.nil?
                  req.body = JSON.generate(payload)
                end
              else
                raise EBSCO::EDS::ApiError, "EBSCO API error: Method #{method} not supported for endpoint #{path}"
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
                  @auth_token = nil
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

      # --
      # attempts to query profile capabilities
      # dummy search just to get the list of available databases
      # ++
      def get_available_databases # :nodoc:
        search({query: 'supercalifragilisticexpialidocious-supercalifragilisticexpialidocious',
                results_per_page: 1,
                mode: 'all',
                include_facets: false}).database_stats
      end

      # :category: Profile Settings Methods
      # Get a list of all available database IDs.
      # Returns Array of IDs.
      def get_available_database_ids
        get_available_databases.map{|item| item[:id]}
      end

      # :category: Profile Settings Methods
      # Determine if a database ID is available in the profile.
      # Returns Boolean.
      def dbid_in_profile(dbid)
        get_available_database_ids.include? dbid
      end

      # :category: Profile Settings Methods
      # Determine if publication matching is available in the profile.
      # Returns Boolean.
      def publication_match_in_profile
        @info.available_related_content_types.include? 'emp'
      end

      # :category: Profile Settings Methods
      # Determine if research starters are available in the profile.
      # Returns Boolean.
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
        if blank?(@auth_token)
          # ip auth
          if (blank?(@user) && blank?(@pass)) || @auth_type.casecmp('ip') == 0
            _response = do_request(:post, path: IP_AUTH_URL)
            @auth_token = _response['AuthToken']
          # user auth
          else
            _response = do_request(:post, path: UID_AUTH_URL, payload: {:UserId => @user, :Password => @pass})
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
end