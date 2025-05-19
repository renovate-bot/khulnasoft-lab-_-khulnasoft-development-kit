# frozen_string_literal: true

RSpec.describe KDK::Services do
  subject(:services) { described_class }

  let(:known_services) { described_class.all_service_names }

  describe '.all' do
    it 'return a list of all Service instances' do
      class_name_without_module = ->(object) { object.class.name.split('::').last.to_sym }

      services.all.each do |service|
        expect(known_services).to include(class_name_without_module.call(service))
      end
    end

    KDK::Services.all.each do |service|
      describe service.class.name do
        specify 'has expected return types', :aggregate_failures do
          expect(service.name).to be_kind_of(String)
          expect(service.command).to be_kind_of(String)
          expect(service.ready_message).to be_kind_of(String).or be_nil
          expect(service.enabled?).to be(true).or be(false)
          expect(service.env).to be_kind_of(Hash)
        end

        it 'has name a proper format' do
          expect(service.name).to match(/^[a-z0-9-]+/)
        end
      end
    end
  end

  describe '.all_service_names' do
    it 'contains names of Service classes' do
      expect(services.all_service_names).to match_array(known_services)
    end
  end

  describe '.fetch' do
    it 'returns an instance of the given service name' do
      expect(services.fetch(:Redis)).to be_a(KDK::Services::Redis)
    end
  end

  describe '.enabled' do
    before do
      services.instance_variable_set(:@enabled, nil)
    end

    it 'contains enabled Service classes' do
      service_classes = [
        KDK::Services::KhulnasoftHttpRouter,
        KDK::Services::KhulnasoftTopologyService,
        KDK::Services::KhulnasoftWorkhorse,
        KDK::Services::Postgresql,
        KDK::Services::RailsBackgroundJobs,
        KDK::Services::RailsWeb,
        KDK::Services::Redis,
        KDK::Services::Sshd,
        KDK::Services::Webpack
      ]

      expect(services.enabled.map(&:class)).to match_array(service_classes)
    end
  end
end
