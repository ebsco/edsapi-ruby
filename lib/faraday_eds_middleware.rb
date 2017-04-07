require 'faraday/eds_middleware'

if Faraday::Middleware.respond_to?(:register_middleware)
  Faraday::Middleware.register_middleware eds_middleware: Faraday::EdsMiddleware
end