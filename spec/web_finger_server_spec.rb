RSpec.describe WebFingerServer do
  describe 'VERSION' do
    it 'is present' do
      expect(WebFingerServer::VERSION).not_to be_nil
    end

    it 'follows semver' do
      expect(WebFingerServer::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
