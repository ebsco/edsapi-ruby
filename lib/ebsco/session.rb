require 'ebsco/version'
require 'ebsco/info'
require 'ebsco/results'
require 'faraday'
require 'faraday_middleware'
require 'logger'
require 'json'

module EBSCO

  class Session

    attr_accessor :auth_token, :session_token, :guest
    attr_writer :user_id, :password

    def initialize(options = {})
      @is_ip_auth = false
      @user_id = options[:user_id]
      @password = options[:password]
      @profile = options[:profile]
      raise InvalidParameterError, 'Session must specify a valid api profile' if blank?(@profile)
      @org = options[:org] || ''
      @guest = options[:guest] ? 'y' : 'n'
      @auth_token = create_auth_token
      @session_token = create_session_token
      @info = get_info
      @max_retries = 2
    end

    # create auth token
    def create_auth_token
      if @auth_token.nil?
        # ip authentication
        if blank?(@user_id) || blank?(@password)
          _response = do_request(:post, path: IP_AUTH_URL)
          @is_ip_auth = true
        # uid authentication
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

    # get info
    def get_info
      _response = do_request(:get, path: INFO_URL)
      EBSCO::Info.new(_response)
    end

    def search(options = {})

      # create search options if this is a new search
      if @search_options.nil?
        @search_options = EBSCO::Options.new(options, @info)
      end
      puts JSON.pretty_generate(@search_options)
      #puts @search_options.inspect

      _response = do_request(:post, path: SEARCH_URL, payload: @search_options)
      #@search_results = EBSCO::Results.new(_response)

      # @current_search_terms = @search_results.searchterms
      #@search_results

    end

    # add actions to an existing search session
    def add_actions(actions)
      search(@search_options.add_actions(actions, @info))
    end

    def connection
      Faraday.new(url: EDS_API_BASE) do |faraday|
        faraday.headers['Content-Type'] = 'application/json;charset=UTF-8'
        faraday.headers['Accept'] = 'application/json'
        faraday.headers['x-sessionToken'] = @session_token ? @session_token : ''
        faraday.headers['x-authenticationToken'] = @auth_token ? @auth_token : ''
        faraday.headers['User-Agent'] = USER_AGENT
        faraday.request :url_encoded
        faraday.response :raise_error
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
            do_request(method, path, payload, attempt+1)
          # auth token missing
          when '104', '107'
            @auth_token = create_auth_token
            do_request(method, path, payload, attempt+1)
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
