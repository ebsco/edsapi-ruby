module EBSCO

  module EDS
    class Error < StandardError
      attr_reader :fault
      def initialize(errors = nil)
        if errors
          @fault = errors
          super(errors[:error_body])
        end
      end
    end

    # raised with passing in invalid or unsupported parameter
    class InvalidParameter < StandardError; end

    # raised when attempting an action that is invalid/unsupported
    class ApiError < StandardError; end

    # Raised when trying an action that is not supported
    class NotImplemented < StandardError; end

    # HTTP related errors

    # raised when EDS returns the HTTP status code 400
    class BadRequest < Error; end

    # raised when EDS returns the HTTP status code 401
    class Unauthorized < Error; end

    # raised when EDS returns the HTTP status code 403
    class Forbidden < Error; end

    # raised when EDS returns the HTTP status code 404
    class NotFound < Error; end

    # Raised when EDS returns the HTTP status code 429
    class TooManyRequests < Error; end

    # Raised when EDS returns the HTTP status code 500
    class InternalServerError < Error; end

    # Raised when EDS returns the HTTP status code 503
    class ServiceUnavailable < Error; end

  end
end
