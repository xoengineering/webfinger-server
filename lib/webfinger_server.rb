require_relative 'webfinger_server/version'
require_relative 'webfinger_server/errors'
require_relative 'webfinger_server/server'
require_relative 'webfinger_server/host_meta'

# WebFinger server implementation (RFC 7033) for the Fediverse
#
# @example Server: Rack middleware
#   use WebFingerServer::Server do |resource, request|
#     look_up_resource(resource)
#   end
#
# @example Host-Meta: Rack middleware
#   use WebFingerServer::HostMeta, domain: 'example.com'
module WebFingerServer
end
