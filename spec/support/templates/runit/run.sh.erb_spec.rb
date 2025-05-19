# frozen_string_literal: true

RSpec.describe 'support/templates/runit/run.sh.erb' do
  let(:source) { |example| example.example_group.top_level_description }
  let(:yaml) { {} }
  let(:service_env) { {} }

  let(:service) do
    instance_double(KDK::Services::Base, env: service_env, command: 'echo hello')
  end

  before do
    stub_kdk_yaml(yaml)
  end

  subject(:output) do
    renderer = KDK::Templates::ErbRenderer.new(source, service_instance: service)
    YAML.safe_load(renderer.render_to_string, permitted_classes: [Symbol])
  end

  describe 'service environment variables' do
    let(:service_env) { { 'FOO' => 'bar' } }

    it 'contains service related environment variables' do
      expect(output).to include("export FOO='bar'")
    end

    it 'merges with global variables' do
      service_env['RAILS_ENV'] = 'staging'

      expect(output).to include("export RAILS_ENV='staging'")
      expect(output).not_to include("export RAILS_ENV='test'")
    end
  end

  describe 'global environment variables' do
    context 'with defaults' do
      it 'contains preset values' do
        expect(output)
          .to include("export RAILS_ENV='development'")
          .and include("export KHULNASOFT_LICENSE_MODE='test'")
          .and include("export CUSTOMER_PORTAL_URL='https://customers.staging.gitlab.com'")
      end
    end

    context 'with extra variables set' do
      let(:yaml) { { 'env' => { 'ACTION_CABLE_IN_APP' => 'false' } } }

      it 'contains RAILS_ENV' do
        expect(output).to include("export RAILS_ENV='development'")
        expect(output).to include("export ACTION_CABLE_IN_APP='false'")
      end
    end

    context 'with variables override' do
      let(:yaml) do
        {
          'env' => {
            'RAILS_ENV' => 'test',
            'KHULNASOFT_LICENSE_MODE' => 'production'
          }
        }
      end

      it 'overrides RAILS_ENV', :aggregate_failures do
        expect(output)
          .to include("export RAILS_ENV='test'")
          .and include("export KHULNASOFT_LICENSE_MODE='production'")
        expect(output).not_to include("export RAILS_ENV='development'")
        expect(output).not_to include("export KHULNASOFT_LICENSE_MODE='test'")
      end
    end

    describe 'jaeger related envvars' do
      let(:yaml) { { 'tracer' => { 'jaeger' => { 'enabled' => enabled } } } }

      context 'when enabled' do
        let(:enabled) { true }

        it 'sets KHULNASOFT_TRACING and KHULNASOFT_TRACING_URL' do
          expect(output)
            .to include('KHULNASOFT_TRACING=')
            .and include('KHULNASOFT_TRACING_URL=')
        end
      end

      context 'when disabled' do
        let(:enabled) { false }

        it 'does not include KHULNASOFT_TRACING and KHULNASOFT_TRACING_URL', :aggregate_failures do
          expect(output).not_to include('KHULNASOFT_TRACING=')
          expect(output).not_to include('KHULNASOFT_TRACING_URL=')
        end
      end
    end
  end
end
