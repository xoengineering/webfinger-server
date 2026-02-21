# WebFinger

[WebFinger](https://www.rfc-editor.org/rfc/rfc7033)
is a protocol for discovering information about people and resources
using standard HTTP methods. It is widely used in the Fediverse to
resolve `acct:user@domain` URIs to ActivityPub actor endpoints.

A pure Ruby implementation of the WebFinger protocol (RFC 7033),
providing both client and Rack middleware server functionality.

## Features

- Pure Ruby  - Works with any Ruby framework or plain scripts
- Client     - Resolve `acct:` URIs to ActivityPub actor endpoints
- Server     - Rack middleware serving `/.well-known/webfinger` responses
- Host-Meta  - Legacy `/.well-known/host-meta` support (XML and JSON)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'web_finger'
```

And then execute:

```sh
bundle install
```

Or install it yourself as:

```sh
gem install web_finger
```

## Usage

### Client

Resolve an `acct:` URI to an ActivityPub actor URI:

```ruby
require 'web_finger'

# One-liner
actor_uri = WebFinger.resolve 'acct:user@mastodon.social'
# => "https://mastodon.social/users/user"

# Or use the client directly for more control
client = WebFinger::Client.new
response = client.fetch 'acct:user@mastodon.social'

response.subject   # => "acct:user@mastodon.social"
response.aliases   # => ["https://mastodon.social/@user"]
response.actor_uri # => "https://mastodon.social/users/user"

# Access individual links
response.link 'self'
# => {"rel"=>"self", "type"=>"application/activity+json", "href"=>"..."}

response.links_for 'http://webfinger.net/rel/profile-page'
# => [{"rel"=>"...", "type"=>"text/html", "href"=>"..."}]
```

#### Client Options

```ruby
# Custom timeout (default: 10 seconds)
client = WebFinger::Client.new timeout: 5

# Disable redirect following (default: true)
client = WebFinger::Client.new follow_redirects: false
```

### Server

Rack middleware that serves WebFinger responses:

```ruby
require 'web_finger'

# config.ru
use WebFinger::Server do |resource, request|
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
use WebFinger::HostMeta, domain: 'example.com'
```

Serves both XML (`/.well-known/host-meta`) and JSON (`/.well-known/host-meta.json`)
responses with LRDD templates pointing to the WebFinger endpoint.

### Framework Integration

#### Rails

```ruby
# config.ru (add before Rails app)
use WebFinger::HostMeta, domain: 'example.com'
use WebFinger::Server do |resource, _request|
  WebFingerLookup.call resource
end
```

#### Sinatra

```ruby
require 'sinatra'
require 'web_finger'

use WebFinger::HostMeta, domain: 'example.com'
use WebFinger::Server do |resource, _request|
  # Look up resource and return JRD hash or nil
end
```

## Error Handling

```ruby
WebFinger::Error            # Base error class
WebFinger::FetchError       # HTTP request failed
WebFinger::ParseError       # Malformed JRD response
WebFinger::ResourceNotFound # Resource returned 404
```

Example:

```ruby
begin
  uri = WebFinger.resolve 'acct:user@example.com'
rescue WebFinger::ResourceNotFound
  puts 'User not found'
rescue WebFinger::FetchError => e
  puts "Request failed: #{e.message}"
rescue WebFinger::ParseError => e
  puts "Invalid response: #{e.message}"
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
https://github.com/xoengineering/web_finger repo.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).

## References

- [WebFinger (RFC 7033)](https://www.rfc-editor.org/rfc/rfc7033)
- [Well-Known URIs (RFC 8615)](https://www.rfc-editor.org/rfc/rfc8615)
- [host-meta (RFC 6415)](https://www.rfc-editor.org/rfc/rfc6415)
- [ActivityPub](https://www.w3.org/TR/activitypub/)
