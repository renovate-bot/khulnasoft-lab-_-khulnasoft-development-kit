# frozen_string_literal: true

RSpec.describe KDK::Services::KhulnasoftHttpRouter do
  describe '#name' do
    it { expect(subject.name).to eq('khulnasoft-http-router') }
  end

  describe '#command' do
    let(:kdk_basepath) { KDK.config.kdk_root }
    let(:key_path) { kdk_basepath.join('localhost.key') }
    let(:cert_path) { kdk_basepath.join('localhost.crt') }
    let(:proxy_host) { KDK.config.workhorse.__listen_address }
    let(:base_command) { format(described_class::BASE_COMMAND, { ip: KDK.config.hostname, port: KDK.config.port, proxy_host: proxy_host, rules_config: KDK.config.khulnasoft_http_router.khulnasoft_rules_config }) }
    let(:https_args) { "--local-protocol https --https-key-path #{key_path} --https-cert-path #{cert_path}" }
    let(:topology_service_args) { format(described_class::TOPOLOGY_SERVICE_COMMAND, { port: KDK.config.khulnasoft_topology_service.rest_port }) }
    let(:full_command) { "#{base_command}#{topology_service_args}" }

    it 'returns the necessary command to run khulnasoft-http-router' do
      expect(subject.command).to eq(full_command)
    end

    context 'when `https` is enabled' do
      before do
        config = {
          'https' => {
            'enabled' => true
          }
        }

        stub_kdk_yaml(config)
      end

      it 'returns the command with the nginx address' do
        expect(subject.command).to eq("#{full_command} #{https_args}")
      end

      context 'with absolute paths for SSL' do
        let(:key_path) { Pathname.new('/kdk/localhost.key').expand_path }
        let(:cert_path) { Pathname.new('/kdk/localhost.crt').expand_path }
        let(:proxy_host) { KDK.config.nginx.__listen_address }

        before do
          config = {
            'https' => {
              'enabled' => true
            },
            'khulnasoft_http_router' => {
              'enabled' => true
            },
            'nginx' => {
              'enabled' => true,
              'ssl' => {
                'certificate' => '/kdk/localhost.crt',
                'key' => '/kdk/localhost.key'
              }
            }
          }

          stub_kdk_yaml(config)
        end

        it 'returns the command with the nginx address' do
          expect(subject.command).to eq("#{full_command} #{https_args}")
        end
      end
    end

    context 'when `khulnasoft_topology_service` is disabled' do
      before do
        config = {
          'khulnasoft_http_router' => {
            'enabled' => true
          },
          'khulnasoft_topology_service' => {
            'enabled' => false
          }
        }

        stub_kdk_yaml(config)
      end

      it 'returns the command with the nginx address' do
        expect(subject.command).to eq(base_command)
      end
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('The HTTP Router is available at http://127.0.0.1:3000.')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(true)
    end
  end

  describe '#env' do
    let(:wrangler_log_path) { Pathname.new(KDK.config.kdk_root.join('tmp/log/khulnasoft-http-router.log')) }

    it 'contains WRANGLER_LOG_PATH by default' do
      expect(subject.env).to eq({
        WRANGLER_LOG_PATH: wrangler_log_path
      })
    end

    context 'when `https` enabled' do
      before do
        config = {
          'https' => {
            'enabled' => true
          }
        }

        stub_kdk_yaml(config)
      end

      it 'returns environment variables' do
        expect(subject.env).to eq({
          NODE_EXTRA_CA_CERTS: "#{KDK.root}/rootCA.pem",
          WRANGLER_LOG_PATH: wrangler_log_path
        })
      end

      it 'uses the mkcert CA root when mkcert is present on the system', :aggregate_failures do
        instance = subject
        allow(Utils).to receive(:executable_exist?).with('mkcert').and_return(true)
        expect(instance).to receive(:mkcert_ca_root_dir).and_return("/path/to/ca_root/")
        expect(instance.env).to eq({
          NODE_EXTRA_CA_CERTS: '/path/to/ca_root/rootCA.pem',
          WRANGLER_LOG_PATH: wrangler_log_path
        })
      end
    end
  end
end
