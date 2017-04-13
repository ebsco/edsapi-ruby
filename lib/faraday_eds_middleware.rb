require 'faraday/eds_caching_middleware'
require 'faraday/eds_exception_middleware'

if Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware eds_caching_middleware: Faraday::EdsCachingMiddleware
  Faraday::Middleware.register_middleware eds_exception_middleware: Faraday::EdsExceptionMiddleware
end