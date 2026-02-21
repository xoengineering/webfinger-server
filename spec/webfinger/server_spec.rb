RSpec.describe Webfinger::Server do
  describe 'VERSION' do
    it 'is present' do
      expect(Webfinger::Server::VERSION).not_to be_nil
    end

    it 'follows semver' do
      expect(Webfinger::Server::VERSION).to match(/\A\d+\.\d+\.\d+\z/)
    end
  end
end
