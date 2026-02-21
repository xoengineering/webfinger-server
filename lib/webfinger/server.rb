require_relative 'server/version'
require_relative 'server/errors'
require_relative 'server/middleware'
require_relative 'server/host_meta'

# WebFinger server implementation (RFC 7033) for the Fediverse
#
# @example Rack middleware
#   use Webfinger::Server::Middleware do |resource, request|
#     look_up_resource(resource)
#   end
#
# @example Host-Meta
#   use Webfinger::Server::HostMeta, domain: 'example.com'
module Webfinger
  module Server
  end
end
