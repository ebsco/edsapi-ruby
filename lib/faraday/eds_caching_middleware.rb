require 'faraday'
require 'uri'
require 'ebsco/eds/configuration'

module Faraday

  class EdsCachingMiddleware < Faraday::Middleware

    def initialize(app, *args)
      super(app)
      options = args.first || {}
      @expires_in    = options.fetch(:expires_in, 30)
      @logger        = options.fetch(:logger, nil)
      @namespace     = options.fetch(:namespace, 'faraday-eds-cache')
      @store         = options.fetch(:store, :memory_store)
      @store_options = options.fetch(:store_options, {})

      @store_options[:namespace] ||= @namespace

      initialize_store

      eds_config = EBSCO::EDS::Configuration.new
      if options[:config]
        @config = eds_config.configure_with(options[:config])
        @config = eds_config.configure if @config.nil?
      else
        @config = eds_config.configure(options)
      end
      (ENV.has_key? 'EDS_API_BASE') ? @api_base = ENV['EDS_API_BASE'] : @api_base = @config[:eds_api_base]

      @info_uri = URI.parse(@api_base + '/edsapi/rest/Info')
      @auth_uri = URI.parse(@api_base + '/authservice/rest/uidauth')
      @search_uri = URI.parse(@api_base + '/edsapi/rest/Search?')
      @retrieve_uri = URI.parse(@api_base + '/edsapi/rest/Retrieve?')

    end

    def call(env)
      dup.call!(env)
    end

    protected

    def call!(env)
      response_env = cached_response(env)

      if response_env
        response_env.response_headers['x-faraday-eds-cache'] = 'HIT'
        to_response(response_env)
      else
        @app.call(env).on_complete do |response_env|
          response_env.response_headers['x-faraday-eds-cache'] = 'MISS'
          cache_response(response_env)
        end
      end
    end

    def cache_response(env)
      #puts 'ENV: ' + env.inspect
      return unless cacheable?(env) && !env.request_headers['x-faraday-eds-cache']

      puts "Cache WRITE: #{key(env)}"
      custom_expires_in = @expires_in
      uri = env.url

      if uri == @auth_uri
        custom_expires_in = 1800 # 30 minutes
        info "#{uri} - Setting custom expires: #{custom_expires_in}"
      end

      if uri == @info_uri
        custom_expires_in = 86400 # 24 hours
        info "#{uri} - Setting custom expires: #{custom_expires_in}"
      end

      if uri.request_uri.start_with?(@search_uri.request_uri)
        custom_expires_in = 1800 # 30 minutes
        info "#{uri} - Setting custom expires: #{custom_expires_in}"
      end

      if uri.request_uri.start_with?(@retrieve_uri.request_uri)
        custom_expires_in = 1800 # 30 minutes
        info "#{uri} - Setting custom expires: #{custom_expires_in}"
      end

      @store.write(key(env), env, expires_in: custom_expires_in)
    end

    def cacheable?(env)
      uri = env.url
      if uri == @auth_uri || uri == @info_uri ||
          uri.request_uri.start_with?(@search_uri.request_uri) ||
          uri.request_uri.start_with?(@retrieve_uri.request_uri)
        if !env.body.nil? && env.body.include?('"jump_request"')
          puts "NOT CACHEABLE URI (jump_request): #{uri}"
          false
        else
          puts "CACHEABLE URI: #{uri}"
          true
        end
      else
        puts "NOT CACHEABLE URI: #{uri}"
        false
      end
    end

    def cached_response(env)

      if cacheable?(env) && !env.request_headers['x-faraday-eds-cache']
        response_env = @store.fetch(key(env))
      end

      if response_env
        puts "Cache HIT: #{key(env)}"
      else
        puts "Cache MISS: #{key(env)}"
      end
      response_env
    end

    def info(message)
      @logger.info(message) unless @logger.nil?
    end

    def key(env)
      env.url
    end

    def initialize_store
      return unless @store.is_a? Symbol
      require 'active_support/cache'
      @store = ActiveSupport::Cache.lookup_store(@store, @store_options)
    end

    def to_response(env)
      env = env.dup
      env.response_headers['x-faraday-eds-cache'] = 'HIT'
      response = Response.new
      response.finish(env) unless env.parallel?
      env.response = response
    end

  end
end