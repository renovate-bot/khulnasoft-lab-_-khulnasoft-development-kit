# frozen_string_literal: true

RSpec.describe KDK::Services::DocsKhulnasoftCom do
  describe '#name' do
    it 'returns docs-gitlab-com' do
      expect(subject.name).to eq('docs-gitlab-com')
    end
  end

  describe '#command' do
    it 'returns non-TLS command if HTTPS is not set' do
      expect(subject.command).to eq("support/exec-cd docs-gitlab-com hugo serve --cleanDestinationDir --baseURL http://127.0.0.1 --port 1313 --bind 127.0.0.1")
    end

    context 'when HTTPS is enabled' do
      before do
        config = {
          'https' => {
            'enabled' => true
          }
        }

        stub_kdk_yaml(config)
      end

      it 'returns TLS-enabled command' do
        expect(subject.command).to eq("support/exec-cd docs-gitlab-com hugo serve --cleanDestinationDir --baseURL https://127.0.0.1 --port 1313 --bind 127.0.0.1 --tlsAuto")
      end
    end
  end

  describe '#enabled?' do
    it 'returns true if set `enabled: true` in the config file' do
      config = {
        'docs_khulnasoft_com' => {
          'enabled' => true
        }
      }

      stub_kdk_yaml(config)

      expect(subject.enabled?).to be(true)
    end

    it 'returns false if set `enabled: false` in the config file' do
      config = {
        'docs_khulnasoft_com' => {
          'enabled' => false
        }
      }

      stub_kdk_yaml(config)

      expect(subject.enabled?).to be(false)
    end
  end
end
