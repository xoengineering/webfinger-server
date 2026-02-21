require_relative 'lib/web_finger/version'

Gem::Specification.new do |spec|
  spec.name     = 'web_finger'
  spec.version  = WebFinger::VERSION
  spec.authors  = ['Shane Becker']
  spec.email    = ['veganstraightedge@gmail.com']
  spec.homepage = 'https://github.com/xoengineering/web_finger'

  spec.summary     = 'WebFinger client and server implementation (RFC 7033)'
  spec.description = <<~DESCRIPTION
    A pure Ruby implementation of the WebFinger protocol (RFC 7033) for the Fediverse,
    providing both client and Rack middleware server functionality.
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
  spec.add_dependency 'http', '~> 5.0'
end
