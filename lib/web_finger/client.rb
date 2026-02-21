require 'http'
require 'json'
require 'uri'

module WebFinger
  # Client for resolving WebFinger resources per RFC 7033
  #
  # @example Fetch full JRD
  #   client = WebFinger::Client.new
  #   response = client.fetch('acct:user@mastodon.social')
  #
  # @example Resolve acct URI to actor URI
  #   uri = client.resolve('acct:user@mastodon.social')
  class Client
    WEBFINGER_PATH = '/.well-known/webfinger'.freeze

    attr_reader :timeout, :follow_redirects

    # @param timeout [Integer] HTTP timeout in seconds (default: 10)
    # @param follow_redirects [Boolean] Whether to follow HTTP redirects (default: true)
    def initialize timeout: 10, follow_redirects: true
      @timeout          = timeout
      @follow_redirects = follow_redirects
    end

    # Fetch the full JRD for a resource
    # @param resource [String] The resource URI (e.g., 'acct:user@domain')
    # @param rel [String, Array<String>, nil] Optional rel type(s) to filter links
    # @return [WebFinger::Response]
    # @raise [WebFinger::FetchError] If HTTP request fails
    # @raise [WebFinger::ParseError] If response is not valid JRD
    # @raise [WebFinger::ResourceNotFound] If resource returns 404
    def fetch resource, rel: nil
      host, port = extract_host_and_port resource
      url        = webfinger_url host, port, resource, rel: rel
      response   = http_client.get url

      raise_for_status response, resource unless response.status.success?

      Response.parse response.body.to_s
    rescue HTTP::Error => e
      raise FetchError, "HTTP request failed: #{e.message}"
    end

    # Resolve a resource URI to its ActivityPub actor URI
    # @param resource [String] The resource URI (e.g., 'acct:user@domain')
    # @return [String, nil] The actor URI, or nil if no ActivityPub link found
    def resolve resource
      fetch(resource).actor_uri
    end

    private

    def http_client
      client = HTTP.timeout timeout
      client = client.follow if follow_redirects
      client
    end

    # Extract host and port from a resource URI
    # Handles acct:, mailto:, https://, bare email, and bare domain formats
    # @return [Array(String, Integer, nil)] host and optional port
    def extract_host_and_port resource
      case resource
      when /\A(acct|mailto):.*@(.+)\z/ # acct:user@host or mailto:user@host
        parse_host_and_port Regexp.last_match(2)
      when %r{\Ahttps?://}             # https://host/path
        uri = URI.parse resource
        [uri.host, uri.port == uri.default_port ? nil : uri.port]
      when /@/                         # bare email: user@host
        parse_host_and_port resource.split('@').last
      when /\A\w+:(.+)\z/              # other schemes: device:host, unknown:user@host
        parse_host_and_port Regexp.last_match(1).split('/').first
      else                             # bare domain: host or host/path
        parse_host_and_port resource.split('/').first
      end
    end

    # Split a "host" or "host:port" string
    def parse_host_and_port host_string
      host, port = host_string.split(':', 2)
      [host, port&.to_i]
    end

    def raise_for_status response, resource
      case response.code
      when 400 then raise BadRequest,       "HTTP 400 Bad Request: #{resource}"
      when 401 then raise Unauthorized,     "HTTP 401 Unauthorized: #{resource}"
      when 403 then raise Forbidden,        "HTTP 403 Forbidden: #{resource}"
      when 404 then raise ResourceNotFound, "Resource not found: #{resource}"
      else          raise FetchError,       "HTTP #{response.code}"
      end
    end

    def webfinger_url host, port, resource, rel: nil
      params = [['resource', resource]]
      Array(rel).each { params << ['rel', it] } if rel
      query = URI.encode_www_form params

      URI::HTTPS.build(
        host:  host,
        port:  port,
        path:  WEBFINGER_PATH,
        query: query
      ).to_s
    end
  end
end
