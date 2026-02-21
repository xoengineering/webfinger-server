require 'json'
require 'rack'

module WebFinger
  # Rack middleware that serves WebFinger responses per RFC 7033
  #
  # @example
  #   use WebFinger::Server do |resource, request|
  #     case resource
  #     when /\Aacct:(.+)@example\.com\z/
  #       { subject: resource, links: [...] }
  #     end
  #   end
  class Server
    WEBFINGER_PATH = '/.well-known/webfinger'.freeze
    CONTENT_TYPE   = 'application/jrd+json'.freeze
    CORS_HEADERS   = { 'Access-Control-Allow-Origin' => '*' }.freeze

    # @param app [#call] The next Rack app in the stack
    # @yield [resource, request] Block called to look up a resource
    # @yieldparam resource [String] The requested resource URI
    # @yieldparam request [Rack::Request] The Rack request object
    # @yieldreturn [Hash, nil] A JRD hash if found, nil if not found
    def initialize app, &handler
      @app     = app
      @handler = handler
    end

    def call env
      request = Rack::Request.new env

      return @app.call env unless webfinger_request? request

      handle_webfinger request
    end

    private

    def webfinger_request? request
      request.get? && request.path_info == WEBFINGER_PATH
    end

    def handle_webfinger request
      resource = request.params['resource']

      return bad_request 'Missing resource parameter' unless resource
      return bad_request 'Invalid resource parameter' if resource.strip.empty?

      jrd = @handler.call resource, request

      return not_found resource unless jrd

      success jrd
    end

    def success jrd
      body = jrd.is_a?(String) ? jrd : JSON.generate(jrd)
      [200, response_headers(CONTENT_TYPE), [body]]
    end

    def bad_request message
      [
        400,
        response_headers('application/json'),
        [JSON.generate({ error: message })]
      ]
    end

    def not_found resource
      [
        404,
        response_headers('application/json'),
        [JSON.generate({ error: "Resource not found: #{resource}" })]
      ]
    end

    def response_headers content_type
      CORS_HEADERS.merge 'Content-Type' => content_type
    end
  end
end
