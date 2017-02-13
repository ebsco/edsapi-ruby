require 'faraday'

module FaradayMiddleware

  class RaiseHttpException < Faraday::Middleware
    def call(env)
      @app.call(env).on_complete do |response|
        case response.status
          when 200
          when 400
            raise EBSCO::BadRequest.new(error_message(response))
          when 401
            raise EBSCO::Unauthorized.new
          when 403
            raise EBSCO::Forbidden.new
          when 404
            raise EBSCO::NotFound.new
          when 429
            raise EBSCO::TooManyRequests.new
          when 500
            raise EBSCO::InternalServerError.new
          when 503
            raise EBSCO::ServiceUnavailable.new
        end
      end
    end

    def initialize(app)
      super app
    end

    private

    def error_message(response)
      #puts response.inspect
      {
          method: response.method,
          url: response.url,
          status: response.status,
          error_body: response.body
      }
    end

  end

end