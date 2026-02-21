require 'json'
require 'rack'

module WebFinger
  # Rack middleware that serves host-meta responses
  # Provides /.well-known/host-meta (XML) and /.well-known/host-meta.json (JSON)
  #
  # @example
  #   use WebFinger::HostMeta, domain: 'example.com'
  class HostMeta
    HOST_META_PATH      = '/.well-known/host-meta'.freeze
    HOST_META_JSON_PATH = '/.well-known/host-meta.json'.freeze

    XRD_TEMPLATE = <<~XML.freeze
      <?xml version="1.0" encoding="UTF-8"?>
      <XRD xmlns="http://docs.oasis-open.org/ns/xri/xrd-1.0">
        <Link rel="lrdd" template="https://%<domain>s/.well-known/webfinger?resource={uri}" />
      </XRD>
    XML

    CORS_HEADERS = {
      'Access-Control-Allow-Origin' => '*'
    }.freeze

    # @param app [#call] The next Rack app in the stack
    # @param domain [String] The domain to use in the host-meta template
    def initialize app, domain:
      @app    = app
      @domain = domain
    end

    def call env
      request = Rack::Request.new env

      return @app.call env unless request.get?

      case request.path_info
      when HOST_META_PATH      then serve_xml
      when HOST_META_JSON_PATH then serve_json
      else @app.call env
      end
    end

    private

    def serve_xml
      body = format XRD_TEMPLATE, domain: @domain
      [200, response_headers('application/xrd+xml'), [body]]
    end

    def serve_json
      body = JSON.generate(
        links: [
          {
            rel:      'lrdd',
            template: "https://#{@domain}/.well-known/webfinger?resource={uri}"
          }
        ]
      )
      [200, response_headers('application/json'), [body]]
    end

    def response_headers content_type
      CORS_HEADERS.merge('Content-Type' => content_type)
    end
  end
end
