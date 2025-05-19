# frozen_string_literal: true

RSpec.describe 'support/templates/registry/config.yml.erb' do
  let(:registry_settings) { {} }
  let(:yaml) { { 'registry' => registry_settings } }
  let(:source) { |example| example.example_group.top_level_description }
  let(:expected_result) do
    {
      'auth' => {
        'token' => {
          'autoredirect' => false,
          'issuer' => 'gitlab-issuer',
          'realm' => 'http://127.0.0.1:3000/jwt/auth',
          'rootcertbundle' => '/home/git/kdk/localhost.crt',
          'service' => 'container_registry'
        }
      },
      'database' => {
        'dbname' => 'registry_dev',
        'enabled' => false,
        'host' => '/home/git/kdk/postgresql',
        'port' => 5432,
        'sslmode' => 'disable'
      },
      'health' => { 'storagedriver' => { 'enabled' => true, 'interval' => '10s', 'threshold' => 3 } },
      'http' => { 'addr' => :'5100', 'headers' => { 'X-Content-Type-Options' => ['nosniff'] } },
      'log' => { 'level' => 'info' },
      'storage' => {
        'cache' => { 'blobdescriptor' => 'inmemory' },
        'delete' => { 'enabled' => true },
        'filesystem' => { 'rootdirectory' => '/home/git/kdk/registry/storage' },
        'maintenance' => {
          'uploadpurging' => { 'age' => '8h', 'dryrun' => false, 'enabled' => true, 'interval' => '1h' }
        }
      },
      'validation' => { 'disabled' => true },
      'version' => 0.1
    }
  end

  before do
    stub_kdk_yaml(yaml)
  end

  subject(:output) do
    renderer = KDK::Templates::ErbRenderer.new(source)
    YAML.safe_load(renderer.render_to_string, permitted_classes: [Symbol])
  end

  context 'with defaults' do
    it { expect(output).to eq(expected_result) }
  end

  context 'with notifications_enabled' do
    let(:registry_settings) { { 'notifications_enabled' => true } }
    let(:expected_result) do
      super().merge(
        'notifications' => {
          'endpoints' => [
            {
              'name' => 'gitlab-rails',
              'url' => 'http://127.0.0.1:3000/api/v4/container_registry_event/events',
              'headers' => {
                'Authorization' => ['notifications_secret']
              },
              'timeout' => '500ms',
              'threshold' => 5,
              'backoff' => '1s'
            }
          ]
        }
      )
    end

    it { expect(output).to eq(expected_result) }
  end
end
