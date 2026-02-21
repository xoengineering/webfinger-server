RSpec.describe WebFinger::Response do
  let :jrd_hash do
    {
      'subject'    => 'acct:user@example.com',
      'aliases'    => [
        'https://example.com/@user',
        'https://example.com/users/user'
      ],
      'properties' => {
        'http://schema.org/name' => 'Example User'
      },
      'links'      => [
        {
          'rel'  => 'http://webfinger.net/rel/profile-page',
          'type' => 'text/html',
          'href' => 'https://example.com/@user'
        },
        {
          'rel'  => 'self',
          'type' => 'application/activity+json',
          'href' => 'https://example.com/users/user'
        },
        {
          'rel'      => 'http://ostatus.org/schema/1.0/subscribe',
          'template' => 'https://example.com/authorize_interaction?uri={uri}'
        }
      ]
    }
  end

  let(:jrd_json) { jrd_hash.to_json }

  describe '.parse' do
    it 'parses a JSON string' do
      response = described_class.parse jrd_json

      expect(response.subject).to eq 'acct:user@example.com'
      expect(response.aliases).to eq ['https://example.com/@user', 'https://example.com/users/user']
      expect(response.properties).to eq('http://schema.org/name' => 'Example User')
      expect(response.links.size).to eq 3
    end

    it 'parses a Hash' do
      response = described_class.parse jrd_hash

      expect(response.subject).to eq 'acct:user@example.com'
    end

    it 'raises ParseError on invalid JSON' do
      expect { described_class.parse 'not json' }.to raise_error WebFinger::ParseError, /Invalid JSON/
    end

    it 'handles missing optional fields' do
      response = described_class.parse({ 'subject' => 'acct:user@example.com' })

      expect(response.aliases).to eq []
      expect(response.properties).to eq({})
      expect(response.links).to eq []
    end
  end

  describe '#link' do
    let(:response) { described_class.parse jrd_hash }

    it 'finds the first link matching a rel' do
      link = response.link 'self'

      expect(link[:href]).to eq 'https://example.com/users/user'
      expect(link[:type]).to eq 'application/activity+json'
    end

    it 'returns nil when no matching link' do
      expect(response.link('nonexistent')).to be_nil
    end
  end

  describe '#links_for' do
    let(:response) { described_class.parse jrd_hash }

    it 'returns all links matching a rel' do
      links = response.links_for 'self'

      expect(links.size).to eq 1
      expect(links.first[:href]).to eq 'https://example.com/users/user'
    end

    it 'returns empty array when no match' do
      expect(response.links_for('nonexistent')).to eq []
    end
  end

  describe '#actor_uri' do
    it 'finds actor URI from self link with application/activity+json' do
      response = described_class.parse jrd_hash

      expect(response.actor_uri).to eq 'https://example.com/users/user'
    end

    it 'finds actor URI from self link with ld+json profile' do
      data = {
        'subject' => 'acct:user@example.com',
        'links'   => [
          {
            'rel'  => 'self',
            'type' => 'application/ld+json; profile="https://www.w3.org/ns/activitystreams"',
            'href' => 'https://example.com/users/user'
          }
        ]
      }
      response = described_class.parse data

      expect(response.actor_uri).to eq 'https://example.com/users/user'
    end

    it 'returns nil when no ActivityPub self link' do
      data = {
        'subject' => 'acct:user@example.com',
        'links'   => [
          {
            'rel'  => 'self',
            'type' => 'text/html',
            'href' => 'https://example.com/@user'
          }
        ]
      }
      response = described_class.parse data

      expect(response.actor_uri).to be_nil
    end

    it 'returns nil when no links at all' do
      response = described_class.parse({ 'subject' => 'acct:user@example.com' })

      expect(response.actor_uri).to be_nil
    end
  end

  describe '#to_h' do
    it 'returns a hash representation' do
      response = described_class.parse jrd_hash
      hash = response.to_h

      expect(hash[:subject]).to eq 'acct:user@example.com'
      expect(hash[:aliases].size).to eq 2
      expect(hash[:links].size).to eq 3
    end
  end

  describe '#to_json' do
    it 'returns a JSON string' do
      response = described_class.parse jrd_hash
      json = response.to_json
      reparsed = JSON.parse json

      expect(reparsed['subject']).to eq 'acct:user@example.com'
      expect(reparsed['links'].size).to eq 3
    end
  end
end
