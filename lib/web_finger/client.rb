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
    # @param resource [String] The resource URI (e.g., "acct:user@domain")
    # @return [WebFinger::Response]
    # @raise [WebFinger::FetchError] If HTTP request fails
    # @raise [WebFinger::ParseError] If response is not valid JRD
    # @raise [WebFinger::ResourceNotFound] If resource returns 404
    def fetch resource
      domain   = extract_domain resource
      url      = webfinger_url domain, resource
      response = http_client.get url

      raise ResourceNotFound, "Resource not found: #{resource}" if response.code == 404
      raise FetchError, "HTTP #{response.code}" unless response.status.success?

      Response.parse response.body.to_s
    rescue HTTP::Error => e
      raise FetchError, "HTTP request failed: #{e.message}"
    end

    # Resolve a resource URI to its ActivityPub actor URI
    # @param resource [String] The resource URI (e.g., "acct:user@domain")
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

    # Extract domain from acct: URI or https: URI
    def extract_domain resource
      if resource.start_with? 'acct:'
        resource.split('@').last
      else
        uri = URI.parse resource
        uri.host || resource
      end
    end

    def webfinger_url domain, resource
      query = URI.encode_www_form resource: resource

      URI::HTTPS.build(
        host:  domain,
        path:  WEBFINGER_PATH,
        query: query
      ).to_s
    end
  end
end
