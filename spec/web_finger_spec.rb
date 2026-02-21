RSpec.describe WebFinger do
  let :jrd_json do
    {
      'subject' => 'acct:user@example.com',
      'aliases' => ['https://example.com/@user'],
      'links'   => [
        {
          'rel'  => 'self',
          'type' => 'application/activity+json',
          'href' => 'https://example.com/users/user'
        }
      ]
    }.to_json
  end

  describe 'VERSION' do
    it 'is present' do
      expect(WebFinger::VERSION).not_to be_nil
    end

    it 'follows semver' do
      expect(WebFinger::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end

  describe '.client' do
    it 'returns a WebFinger::Client' do
      expect(described_class.client).to be_a WebFinger::Client
    end
  end

  describe '.resolve' do
    it 'resolves an acct URI to an actor URI' do
      stub_request(:get, 'https://example.com/.well-known/webfinger?resource=acct%3Auser%40example.com')
        .to_return status: 200, body: jrd_json

      uri = described_class.resolve 'acct:user@example.com'

      expect(uri).to eq 'https://example.com/users/user'
    end
  end
end
