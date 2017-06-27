require 'faraday'
require 'uri'

module Faraday

  class EdsCachingMiddleware < Faraday::Middleware

    INFO_URI = URI.parse('https://eds-api.ebscohost.com/edsapi/rest/Info')
    AUTH_URI = URI.parse('https://eds-api.ebscohost.com/authservice/rest/uidauth')

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
      return unless cacheable?(env) && !env.request_headers['x-faraday-eds-cache']

      info "Cache WRITE: #{key(env)}"
      custom_expires_in = @expires_in
      uri = env.url

      if uri == AUTH_URI
        custom_expires_in = 1800 # 30 minutes
        info "#{uri} - Setting custom expires: #{custom_expires_in}"
      end

      if uri == INFO_URI
        custom_expires_in = 86400 # 24 hours
        info "#{uri} - Setting custom expires: #{custom_expires_in}"
      end

      @store.write(key(env), env, expires_in: custom_expires_in)
    end

    def cacheable?(env)
      uri = env.url
      if uri == AUTH_URI || uri == INFO_URI
        info "CACHEABLE URI: #{uri}"
        true
      else
        info "NOT CACHEABLE URI: #{uri}"
        false
      end
    end

    def cached_response(env)
      if cacheable?(env) && !env.request_headers['x-faraday-eds-cache']
        response_env = @store.fetch(key(env))
      end

      if response_env
        info "Cache HIT: #{key(env)}"
      else
        info "Cache MISS: #{key(env)}"
      end

      # info "CACHE: #{response_env.inspect}"

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