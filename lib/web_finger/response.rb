require 'json'

module WebFinger
  # Wraps a parsed JRD (JSON Resource Descriptor) per RFC 7033
  #
  # @example
  #   response = WebFinger::Response.parse('{"subject":"acct:user@example.com",...}')
  #   response.subject    # => "acct:user@example.com"
  #   response.actor_uri  # => "https://example.com/users/user"
  class Response
    ACTIVITYPUB_TYPES = [
      'application/activity+json',
      'application/ld+json; profile="https://www.w3.org/ns/activitystreams"'
    ].freeze

    attr_reader :subject, :aliases, :properties, :links

    # Parse a JRD from JSON string or Hash
    # @param json [String, Hash] Raw JSON or pre-parsed Hash
    # @return [WebFinger::Response]
    # @raise [WebFinger::ParseError] If JSON is malformed
    def self.parse json
      data = json.is_a?(String) ? JSON.parse(json, symbolize_names: true) : deep_symbolize_keys(json)

      new subject:    data[:subject],
          aliases:    data[:aliases] || [],
          properties: data[:properties] || {},
          links:      data[:links] || []
    rescue JSON::ParserError => e
      raise ParseError, "Invalid JSON: #{e.message}"
    end

    def initialize subject:, aliases: [], properties: {}, links: []
      @subject    = subject
      @aliases    = aliases
      @properties = properties
      @links      = links
    end

    # Find the first link matching a given rel
    # @param rel [String] The relation type
    # @return [Hash, nil]
    def link rel
      links.find { it[:rel] == rel }
    end

    # Find all links matching a given rel
    # @param rel [String] The relation type
    # @return [Array<Hash>]
    def links_for rel
      links.select { it[:rel] == rel }
    end

    # Convenience: find the ActivityPub actor URI
    # @return [String, nil]
    def actor_uri
      self_links = links_for 'self'
      ap_link = self_links.find { ACTIVITYPUB_TYPES.include? it[:type] }
      ap_link&.dig :href
    end

    # Convert to Hash
    # @return [Hash]
    def to_h
      {
        subject:    subject,
        aliases:    aliases,
        properties: properties,
        links:      links
      }.compact
    end

    # Convert to JSON string
    # @return [String]
    def to_json(*) = to_h.to_json(*)

    def self.deep_symbolize_keys hash
      hash.each_with_object({}) do |(key, value), result|
        sym_key = key.to_sym
        result[sym_key] = case value
                          when Hash  then deep_symbolize_keys(value)
                          when Array then value.map { it.is_a?(Hash) ? deep_symbolize_keys(it) : it }
                          else value
                          end
      end
    end

    private_class_method :deep_symbolize_keys
  end
end
