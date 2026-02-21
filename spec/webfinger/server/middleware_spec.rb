require 'rack/test'

RSpec.describe Webfinger::Server::Middleware do
  include Rack::Test::Methods

  let(:inner_app) { ->(_env) { [200, { 'content-type': 'text/plain' }, ['OK']] } }

  let :jrd_data do
    {
      subject: 'acct:user@example.com',
      links:   [
        { rel: 'self', type: 'application/activity+json', href: 'https://example.com/users/user' }
      ]
    }
  end

  let :app do
    data = jrd_data
    described_class.new(inner_app) do |resource, _request|
      resource == 'acct:user@example.com' ? data : nil
    end
  end

  describe 'GET /.well-known/webfinger' do
    it 'returns 200 with JRD for known resource' do
      get '/.well-known/webfinger', resource: 'acct:user@example.com'

      expect(last_response.status).to eq 200

      body = JSON.parse last_response.body
      expect(body['subject']).to eq 'acct:user@example.com'
      expect(body['links'].size).to eq 1
    end

    it 'returns application/jrd+json content type' do
      get '/.well-known/webfinger', resource: 'acct:user@example.com'

      expect(last_response.content_type).to eq 'application/jrd+json'
    end

    it 'returns Access-Control-Allow-Origin header' do
      get '/.well-known/webfinger', resource: 'acct:user@example.com'

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq '*'
    end

    it 'returns 400 when resource parameter is missing' do
      get '/.well-known/webfinger'

      expect(last_response.status).to eq 400

      body = JSON.parse last_response.body
      expect(body['error']).to match(/Missing resource/)
    end

    it 'returns 400 when resource parameter is empty' do
      get '/.well-known/webfinger', resource: '   '

      expect(last_response.status).to eq 400

      body = JSON.parse last_response.body
      expect(body['error']).to match(/Invalid resource/)
    end

    it 'returns 404 when handler returns nil' do
      get '/.well-known/webfinger', resource: 'acct:nobody@example.com'

      expect(last_response.status).to eq 404

      body = JSON.parse last_response.body
      expect(body['error']).to match(/not found/)
    end
  end

  describe 'passthrough' do
    it 'passes non-webfinger requests to inner app' do
      get '/other-path'

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'OK'
    end

    it 'passes non-GET requests to inner app' do
      post '/.well-known/webfinger', resource: 'acct:user@example.com'

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'OK'
    end
  end
end
