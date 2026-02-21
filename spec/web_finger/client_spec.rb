RSpec.describe WebFinger::Client do
  let(:client) { described_class.new }

  let :jrd_json do
    {
      'subject' => 'acct:user@example.com',
      'aliases' => [
        'https://example.com/@user',
        'https://example.com/users/user'
      ],
      'links'   => [
        {
          'rel'  => 'http://webfinger.net/rel/profile-page',
          'type' => 'text/html',
          'href' => 'https://example.com/@user'
        },
        {
          'rel'  => 'self',
          'type' => 'application/activity+json',
          'href' => 'https://example.com/users/user'
        }
      ]
    }.to_json
  end

  describe '#fetch' do
    it 'fetches and parses JRD for an acct: URI' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_return status: 200, body: jrd_json, headers: { 'Content-Type' => 'application/jrd+json' }

      response = client.fetch 'acct:user@example.com'

      expect(response).to be_a WebFinger::Response
      expect(response.subject).to eq 'acct:user@example.com'
      expect(response.links.size).to eq 2
    end

    it 'fetches JRD for an https: URI' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=https%3A%2F%2Fexample.com%2Fusers%2Fuser')
        .to_return status: 200, body: jrd_json, headers: { 'Content-Type' => 'application/jrd+json' }

      response = client.fetch 'https://example.com/users/user'

      expect(response).to be_a WebFinger::Response
    end

    it 'raises ResourceNotFound on 404' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Anobody%40example.com')
        .to_return status: 404

      expect { client.fetch 'acct:nobody@example.com' }.to raise_error WebFinger::ResourceNotFound, /not found/
    end

    it 'raises FetchError on 500' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_return status: 500

      expect { client.fetch 'acct:user@example.com' }.to raise_error WebFinger::FetchError, /HTTP 500/
    end

    it 'raises FetchError on network error' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_raise HTTP::ConnectionError.new('Connection refused')

      expect { client.fetch 'acct:user@example.com' }.to raise_error WebFinger::FetchError, /Connection refused/
    end

    it 'passes a single rel parameter' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?rel=self&resource=acct%3Auser%40example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'acct:user@example.com', rel: 'self'

      expect(response).to be_a WebFinger::Response
    end

    it 'passes multiple rel parameters' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?rel=self&rel=http%3A%2F%2Fwebfinger.net%2Frel%2Fprofile-page&resource=acct%3Auser%40example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'acct:user@example.com', rel: ['self', 'http://webfinger.net/rel/profile-page']

      expect(response).to be_a WebFinger::Response
    end

    it 'raises ParseError on invalid JSON response' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_return status: 200, body: 'not json'

      expect { client.fetch 'acct:user@example.com' }.to raise_error WebFinger::ParseError, /Invalid JSON/
    end
  end

  describe '#resolve' do
    it 'resolves an acct URI to an actor URI' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_return status: 200, body: jrd_json

      uri = client.resolve 'acct:user@example.com'

      expect(uri).to eq 'https://example.com/users/user'
    end

    it 'returns nil when no ActivityPub link in JRD' do
      no_activity_pub_jrd = {
        'subject' => 'acct:user@example.com',
        'links'   => [
          { 'rel' => 'http://webfinger.net/rel/profile-page', 'type' => 'text/html', 'href' => 'https://example.com/@user' }
        ]
      }.to_json

      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_return status: 200, body: no_activity_pub_jrd

      expect(client.resolve('acct:user@example.com')).to be_nil
    end

    it 'propagates ResourceNotFound' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Anobody%40example.com')
        .to_return status: 404

      expect { client.resolve 'acct:nobody@example.com' }.to raise_error WebFinger::ResourceNotFound
    end
  end

  describe '#extract_host_and_port (via fetch)' do
    it 'handles acct: URI with port' do
      stub_request(:get, 'https://example.com:8080/.well-known/webfinger?resource=acct%3Auser%40example.com%3A8080')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'acct:user@example.com:8080'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles bare email (no acct: prefix)' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=user%40example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'user@example.com'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles dotted local part' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=first.last%40example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'first.last@example.com'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles mailto: URI' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=mailto%3Auser%40example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'mailto:user@example.com'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles bare domain' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'example.com'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles bare domain with path' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=example.com%2F%7Euser%2F')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'example.com/~user/'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles bare domain with port' do
      stub_request(:get, 'https://example.com:8080/.well-known/webfinger?resource=example.com%3A8080')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'example.com:8080'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles https: URI with port' do
      stub_request(:get, 'https://example.com:8080/.well-known/webfinger?resource=https%3A%2F%2Fexample.com%3A8080%2Fusers%2Fuser')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'https://example.com:8080/users/user'

      expect(response).to be_a WebFinger::Response
    end

    it 'handles subdomain' do
      stub_request(:get, 'https://social.example.com/.well-known/webfinger?resource=acct%3Auser%40social.example.com')
        .to_return status: 200, body: jrd_json

      response = client.fetch 'acct:user@social.example.com'

      expect(response).to be_a WebFinger::Response
    end
  end

  describe 'initialization' do
    it 'defaults to 10 second timeout' do
      expect(client.timeout).to eq 10
    end

    it 'defaults to following redirects' do
      expect(client.follow_redirects).to be true
    end

    it 'accepts custom timeout' do
      custom = described_class.new timeout: 30
      expect(custom.timeout).to eq 30
    end

    it 'accepts custom follow_redirects' do
      custom = described_class.new follow_redirects: false
      expect(custom.follow_redirects).to be false
    end
  end
end
