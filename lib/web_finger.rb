require_relative 'web_finger/version'
require_relative 'web_finger/errors'
require_relative 'web_finger/response'
require_relative 'web_finger/client'
require_relative 'web_finger/server'
require_relative 'web_finger/host_meta'

# WebFinger protocol implementation (RFC 7033) for the Fediverse
#
# @example Client: resolve acct URI to actor URI
#   actor_uri = WebFinger.resolve('acct:user@mastodon.social')
#
# @example Client: fetch full JRD
#   response = WebFinger.client.fetch('acct:user@mastodon.social')
#   response.subject   # => 'acct:user@mastodon.social'
#   response.actor_uri # => 'https://mastodon.social/users/user'
#
# @example Server: Rack middleware
#   use WebFinger::Server do |resource, request|
#     look_up_resource(resource)
#   end
module WebFinger
  class << self
    # Create a new WebFinger client
    # @return [WebFinger::Client]
    def client = Client.new

    # Convenience: resolve a resource URI to its ActivityPub actor URI
    # @param resource [String] The resource URI (e.g., "acct:user@domain")
    # @return [String, nil] The actor URI
    def resolve resource
      Client.new.resolve resource
    end
  end
end
