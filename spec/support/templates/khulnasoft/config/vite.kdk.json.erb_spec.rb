# frozen_string_literal: true

RSpec.describe 'support/templates/khulnasoft/config/vite.kdk.json.erb' do
  let(:kdk_basepath) { KDK.config.kdk_root }
  let(:key_path) { kdk_basepath.join('localhost.key').to_s }
  let(:cert_path) { kdk_basepath.join('localhost.crt').to_s }
  let(:vite_settings) { {} }
  let(:nginx_settings) { {} }
  let(:yaml) do
    {
      'hostname' => 'kdk.test',
      'vite' => vite_settings,
      'nginx' => nginx_settings,
      'webpack' => {
        'enabled' => false
      }
    }
  end

  let(:source) { |example| example.example_group.top_level_description }

  before do
    config = KDK::Config.new(yaml: yaml)
    allow(KDK).to receive(:config).and_return(config)
  end

  subject(:output) do
    renderer = KDK::Templates::ErbRenderer.new(source)
    JSON.parse(renderer.render_to_string)
  end

  context 'with defaults' do
    let(:vite_settings) { {} }

    it 'equals default settings' do
      expect(output).to eq({
        'enabled' => false,
        'public_host' => 'kdk.test',
        'host' => '127.0.0.1',
        'port' => 3038,
        'hmr' => {
          'clientPort' => 3038,
          'host' => '127.0.0.1',
          'protocol' => 'ws'
        }
      })
    end
  end

  context 'with hot module reloading disabled' do
    let(:vite_settings) {  { 'enabled' => true, 'port' => 3011, 'hot_module_reloading' => false } }

    it 'sets hmr to nil' do
      expect(output).to eq({
        'enabled' => true,
        'public_host' => 'kdk.test',
        'host' => '127.0.0.1',
        'port' => 3011,
        'hmr' => nil
      })
    end
  end

  context 'when vite is enabled' do
    let(:vite_settings) { { 'enabled' => true, 'port' => 3011 } }

    it 'equals default settings' do
      expect(output).to eq({
        'enabled' => true,
        'public_host' => 'kdk.test',
        'host' => '127.0.0.1',
        'port' => 3011,
        'hmr' => {
          'clientPort' => 3011,
          'host' => '127.0.0.1',
          'protocol' => 'ws'
        }
      })
    end

    context 'when HTTPS is enabled' do
      before do
        yaml['https'] = { 'enabled' => true }
      end

      it 'sets the protocol to ws' do
        expect(output).to eq({
          'enabled' => true,
          'public_host' => 'kdk.test',
          'host' => '127.0.0.1',
          'port' => 3011,
          'hmr' => {
            'clientPort' => 3011,
            'host' => '127.0.0.1',
            'protocol' => 'wss'
          },
          'https' => {
            'enabled' => true,
            'key' => key_path,
            'certificate' => cert_path
          }
        })
      end
    end

    context 'when HTTPS is only enabled for vite' do
      let(:vite_settings) { { 'enabled' => true, 'https' => { 'enabled' => true } } }

      it 'sets the protocol to ws' do
        expect(output).to eq({
          'enabled' => true,
          'public_host' => 'kdk.test',
          'host' => '127.0.0.1',
          'port' => 3038,
          'hmr' => {
            'clientPort' => 3038,
            'host' => '127.0.0.1',
            'protocol' => 'wss'
          },
          'https' => {
            'enabled' => true,
            'key' => key_path,
            'certificate' => cert_path
          }
        })
      end
    end

    context 'and nginx is enabled' do
      let(:nginx_settings) { { 'enabled' => true, 'http' => { 'port' => 8080 } } }

      it 'sets the nginx port in hash' do
        expect(output).to eq({
          'enabled' => true,
          'public_host' => 'kdk.test',
          'host' => '127.0.0.1',
          'port' => 3011,
          'hmr' => {
            'clientPort' => 8080,
            'host' => 'kdk.test',
            'protocol' => 'ws'
          }
        })
      end

      context 'when HTTPS is enabled' do
        before do
          yaml['https'] = { 'enabled' => true }
        end

        it 'sets the protocol to wss' do
          expect(output).to eq({
            'enabled' => true,
            'public_host' => 'kdk.test',
            'host' => '127.0.0.1',
            'port' => 3011,
            'hmr' => {
              'clientPort' => 8080,
              'host' => 'kdk.test',
              'protocol' => 'wss'
            },
            'https' => {
              'enabled' => true,
              'key' => key_path,
              'certificate' => cert_path
            }
          })
        end
      end
    end
  end
end
