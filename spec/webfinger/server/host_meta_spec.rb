require 'rack/test'

RSpec.describe Webfinger::Server::HostMeta do
  include Rack::Test::Methods

  let(:inner_app) { ->(_env) { [200, { 'content-type': 'text/plain' }, ['OK']] } }
  let(:app) { described_class.new inner_app, domain: 'example.com' }

  describe 'GET /.well-known/host-meta' do
    it 'returns XML with WebFinger template' do
      get '/.well-known/host-meta'

      expect(last_response.status).to eq 200

      expect(last_response.body).to include 'https://example.com/.well-known/webfinger?resource={uri}'
      expect(last_response.body).to include '<Link rel="lrdd"'
    end

    it 'returns application/xrd+xml content type' do
      get '/.well-known/host-meta'

      expect(last_response.content_type).to eq 'application/xrd+xml'
    end

    it 'returns CORS header' do
      get '/.well-known/host-meta'

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq '*'
    end
  end

  describe 'GET /.well-known/host-meta.json' do
    it 'returns JSON with WebFinger template' do
      get '/.well-known/host-meta.json'

      expect(last_response.status).to eq 200

      body = JSON.parse last_response.body
      link = body['links'].first

      expect(link['rel']).to eq 'lrdd'
      expect(link['template']).to eq 'https://example.com/.well-known/webfinger?resource={uri}'
    end

    it 'returns application/json content type' do
      get '/.well-known/host-meta.json'

      expect(last_response.content_type).to eq 'application/json'
    end

    it 'returns CORS header' do
      get '/.well-known/host-meta.json'

      expect(last_response.headers['Access-Control-Allow-Origin']).to eq '*'
    end
  end

  describe 'passthrough' do
    it 'passes other requests to inner app' do
      get '/other-path'

      expect(last_response.status).to eq 200
      expect(last_response.body).to eq 'OK'
    end
  end
end
