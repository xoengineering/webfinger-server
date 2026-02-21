require_relative 'lib/webfinger_server/version'

Gem::Specification.new do |spec|
  spec.name     = 'webfinger-server'
  spec.version  = WebFingerServer::VERSION
  spec.authors  = ['Shane Becker']
  spec.email    = ['veganstraightedge@gmail.com']
  spec.homepage = 'https://github.com/xoengineering/webfinger-server'

  spec.summary     = 'WebFinger server Rack middleware (RFC 7033)'
  spec.description = <<~DESCRIPTION
    Rack middleware for serving WebFinger (RFC 7033) and host-meta responses.
    Pairs with the webfinger gem for client functionality.
  DESCRIPTION

  spec.license = 'MIT'

  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.metadata['rubygems_mfa_required'] = 'true'
  spec.required_ruby_version             = '>= 4.0.0'

  spec.files = Dir.glob(
    %w[
      lib/**/*.rb
      CHANGELOG.md
      LICENSE.txt
      README.md
    ]
  ).reject { File.directory? it }

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { File.basename it }
  spec.require_paths = ['lib']

  # Runtime dependencies
  spec.add_dependency 'rack', '~> 3.0'
end
