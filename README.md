# WebFinger Server

Rack middleware for serving [WebFinger](https://www.rfc-editor.org/rfc/rfc7033)
(RFC 7033) and host-meta responses. Widely used in the Fediverse to let others
discover your users' ActivityPub actor endpoints.

For **client** functionality (looking up remote users), see the
[webfinger](https://rubygems.org/gems/webfinger) gem.

## Features

- Framework agnostic - Works with any Rack-based Ruby framework
- Server    - Rack middleware for `/.well-known/webfinger` responses
- Host-Meta - Legacy `/.well-known/host-meta` support (XML and JSON)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'webfinger-server'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install webfinger-server
```

## Usage

### Server

Rack middleware that serves WebFinger responses:

```ruby
require 'webfinger/server'

# config.ru
use Webfinger::Server::Middleware do |resource, request|
  case resource
  when /\Aacct:(.+)@example\.com\z/
    user = User.find_by username: Regexp.last_match(1)
    next nil unless user

    {
      subject: resource,
      aliases: ["https://example.com/@#{user.username}"],
      links:   [
        {
          rel:  'self',
          type: 'application/activity+json',
          href: "https://example.com/users/#{user.username}"
        },
        {
          rel:  'http://webfinger.net/rel/profile-page',
          type: 'text/html',
          href: "https://example.com/@#{user.username}"
        }
      ]
    }
  end
end

run MyApp
```

The handler block receives the `resource` parameter and the Rack `request`.
Return a Hash (JRD) for found resources, or `nil` for 404.

The middleware handles:

- `application/jrd+json` content type
- `Access-Control-Allow-Origin: *` CORS header
- 400 for missing or empty `resource` parameter
- 404 when the handler returns `nil`

### Host-Meta

Optional Rack middleware for legacy `/.well-known/host-meta` support:

```ruby
use Webfinger::Server::HostMeta, domain: 'example.com'
```

Serves both XML (`/.well-known/host-meta`) and JSON (`/.well-known/host-meta.json`)
responses with LRDD templates pointing to the WebFinger endpoint.

### Framework Integration

#### Rails

```ruby
# config.ru (add before Rails app)
use Webfinger::Server::HostMeta, domain: 'example.com'
use Webfinger::Server::Middleware do |resource, _request|
  # Look up resource and return JRD hash or nil
end
```

#### Sinatra

```ruby
require 'sinatra'
require 'webfinger/server'

use Webfinger::Server::HostMeta, domain: 'example.com'
use Webfinger::Server::Middleware do |resource, _request|
  # Look up resource and return JRD hash or nil
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```sh
bundle exec rspec
```

### Running RuboCop

```sh
bundle exec rubocop
```

### Running All Checks

```sh
bundle exec rake
```

## Contributing

Bug reports and pull requests are welcome on GitHub at the
https://github.com/xoengineering/webfinger-server repo.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## References

- [WebFinger (RFC 7033)](https://www.rfc-editor.org/rfc/rfc7033)
- [Well-Known URIs (RFC 8615)](https://www.rfc-editor.org/rfc/rfc8615)
- [host-meta (RFC 6415)](https://www.rfc-editor.org/rfc/rfc6415)
- [ActivityPub](https://www.w3.org/TR/activitypub/)
