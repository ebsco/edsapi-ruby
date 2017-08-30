require 'faraday'

module Faraday

  class EdsExceptionMiddleware < Faraday::Middleware

  def initialize(app)
      super app
    end

    def call(env)
      begin
        @app.call(env).on_complete do |response|
          case response.status
            when 200
            when 400
              raise EBSCO::EDS::BadRequest.new(error_message(response))
            # when 401
            #   raise EBSCO::EDS::Unauthorized.new
            # when 403
            #   raise EBSCO::EDS::Forbidden.new
            # when 404
            #   raise EBSCO::EDS::NotFound.new
            # when 429
            #   raise EBSCO::EDS::TooManyRequests.new
            when 500
              raise EBSCO::EDS::InternalServerError.new
            when 503
              raise EBSCO::EDS::ServiceUnavailable.new
            else
              raise EBSCO::EDS::BadRequest.new(error_message(response))
          end
        end
        rescue Faraday::ConnectionFailed
          raise EBSCO::EDS::ConnectionFailed.new
      end
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