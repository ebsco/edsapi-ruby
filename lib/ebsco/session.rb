require 'ebsco/version'
require 'ebsco/info'
require 'ebsco/results'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'json'

module EBSCO

  class Session

    attr_accessor :auth_token, :session_token, :guest, :info
    attr_writer :user_id, :password

    def initialize(options = {})
      
      if options.has_key? :user_id
        @user_id = options[:user_id]
      elsif ENV.has_key? 'EDS_USER_ID'
        @user_id = ENV['EDS_USER_ID']
      end

      if options.has_key? :password
        @password = options[:password]
      elsif ENV.has_key? 'EDS_USER_PASSWORD'
        @password = ENV['EDS_USER_PASSWORD']
      end

      if options.has_key? :profile
        @profile = options[:profile]
      elsif ENV.has_key? 'EDS_PROFILE'
        @profile = ENV['EDS_PROFILE']
      end
      raise InvalidParameterError, 'Session must specify a valid api profile.' if blank?(@profile)

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

      @is_ip_auth = false
      @max_retries = 2
      @auth_token = create_auth_token
      @session_token = create_session_token
      @info = EBSCO::Info.new(do_request(:get, path: INFO_URL))
      @current_page = 0

    end

    # create auth token
    def create_auth_token
      if @auth_token.nil?
        # ip auth
        if blank?(@user_id) && blank?(@password)
          _response = do_request(:post, path: IP_AUTH_URL)
          @is_ip_auth = true
        # user auth
        else
          _response = do_request(:post, path: UID_AUTH_URL, payload: {:UserId => @user_id, :Password => @password})
          @auth_token = _response['AuthToken']
          @auth_timeout = _response['AuthTimeout']
         end
      end
      @auth_token
    end

    # create session token
    def create_session_token
      _response = do_request(:post, path: CREATE_SESSION_URL, payload: {:Profile => @profile, :Guest => @guest})
      @session_token = _response['SessionToken']
    end

    # end session
    def end
      # todo: catch when there is no valid session?
      do_request(:post, path: END_SESSION_URL, payload: {:SessionToken => @session_token})
      connection.headers['x-sessionToken'] = ''
      @session_token = ''
    end

    def search(options = {}, add_actions = false)

      # create/recreate the search options if nil or not passing actions
      if @search_options.nil? || !add_actions
        @search_options = EBSCO::Options.new(options, @info)
      end
      #puts JSON.pretty_generate(@search_options)
      _response = do_request(:post, path: SEARCH_URL, payload: @search_options)
      @search_results = EBSCO::Results.new(_response)
      #@current_search_terms = @search_results.searchterms
      @current_page = @search_results.page_number
      @search_results
    end

    def retrieve(dbid:, an:, highlight: nil, ebook: 'ebook-pdf')
      payload = {:DbId => dbid, :An => an, :HighlighTerms => highlight, :EbookPreferredFormat =>  ebook}
      retrieve_response = do_request(:post, path: RETRIEVE_URL, payload: payload)
      EBSCO::Record.new(retrieve_response)
    end

    # add actions to an existing search session
    def add_actions(actions)
      search(@search_options.add_actions(actions, @info), true)
    end

    def next_page
      page = @current_page + 1
      get_page(page)
    end

    def prev_page
      get_page([1, @current_page - 1].sort.last)
    end

    def get_page(page = 1)
      add_actions("GoToPage(#{page})")
    end

    def connection
      Faraday.new(url: EDS_API_BASE) do |faraday|
        faraday.headers['Content-Type'] = 'application/json;charset=UTF-8'
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['x-sessionToken'] = @session_token ? @session_token : ''
        faraday.headers['x-authenticationToken'] = @auth_token ? @auth_token : ''
        faraday.headers['User-Agent'] = USER_AGENT
        faraday.request :url_encoded
        #faraday.response :raise_error
        faraday.response :json, :content_type => /\bjson$/
        faraday.response :logger, Logger.new(LOG)
        faraday.adapter Faraday.default_adapter
      end
    end

    def do_request(method, path:, payload: nil, attempt: 0)
      resp = connection.send(method) do |req|
        case method
          when :get, :delete
            req.url path
          when :post, :put
            req.url path
            req.body = JSON.generate(payload)
          else
            raise ApiError, "EBSCO API error:\nMethod #{method} not supported for endpoint #{path}"
        end
      end

      if attempt > MAX_ATTEMPTS
        raise ApiError, 'EBSCO API error:\nAttempts to create session token failed.'
      end

      # errors originating from uidauth endpoint
      if resp.body['ErrorCode']
        raise ApiError, "EBSCO API returned error:\n" +
            "Code: #{resp.body['ErrorCode']}\n" +
            "Reason: #{resp.body['Reason']}\n" +
            "Details:\n#{resp.body['AdditionalDetail']}"
      end
      # errors originating from all other endpoints
      if resp.body['ErrorNumber']
        case resp.body['ErrorNumber']
          # session token missing
          when '108', '109'
            @session_token = create_session_token
            do_request(method, path: path, payload: payload, attempt: attempt+1)
          # auth token missing
          when '104', '107'
            @auth_token = create_auth_token
            do_request(method, path: path, payload: payload, attempt: attempt+1)
          else
            raise ApiError, "EBSCO API returned error:\n" +
                "Number: #{resp.body['ErrorNumber']}\n" +
                "Description: #{resp.body['ErrorDescription']}\n" +
                "Details:\n#{resp.body['DetailedErrorDescription']}"
        end
      end
      resp.body
    end

    def blank?(var)
      var.nil? || var.respond_to?(:length) && var.length == 0
    end

  end
end
