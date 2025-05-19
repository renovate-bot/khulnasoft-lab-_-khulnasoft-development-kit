# frozen_string_literal: true

RSpec.describe KDK::ConfigType::Port do
  let(:config) { KDK.config }
  let(:parent) { config }
  let(:key) { 'port' }
  let(:service_name) { 'kdk' }
  let(:value) { nil }
  let(:yaml) { { key => value } }
  let(:blk) { nil }
  let(:builder) { KDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &blk) }

  subject { described_class.new(parent: parent, builder: builder, service_name: service_name) }

  before do
    stub_pg_bindir
    stub_kdk_yaml(yaml)
  end

  describe '#parse' do
    context 'when value is initialized with an integer' do
      let(:value) { 123 }

      it 'returns parsed value' do
        expect(subject.parse(value)).to eq(123)
      end
    end

    context 'when value is initialized with a string' do
      let(:value) { 'test' }

      it 'raises an exception' do
        expect { subject.parse(value) }.to raise_error(TypeError, "Value 'test' for setting '#{key}' is not a valid port.")
      end
    end

    context 'when value is initialized with a port that is already allocated' do
      let(:value) { 3808 }

      before do
        config.port_manager.claim(3808, 'webpack')
      end

      context "and the allocated port's service does not respond to enabled" do
        it 'raises an exception' do
          allow(parent).to receive(:respond_to?).with(:enabled?).and_return(false)

          expect { subject.parse(value) }.to raise_error(KDK::StandardErrorWithMessage, "Value '#{value}' for setting '#{key}' is not a valid port - Port 3808 is already allocated for service 'webpack'.")
        end
      end

      context "but the allocated port's service is not enabled" do
        it 'does not raise an exception' do
          allow(parent).to receive(:enabled?).and_return(false)

          expect(subject.parse(value)).to eq(value)
        end
      end

      context "and the allocated port's service is enabled" do
        it 'raises an exception' do
          allow(parent).to receive(:enabled?).and_return(true)

          expect { subject.parse(value) }.to raise_error(KDK::StandardErrorWithMessage, "Value '#{value}' for setting '#{key}' is not a valid port - Port 3808 is already allocated for service 'webpack'.")
        end
      end
    end
  end

  describe '#default_value' do
    context 'when the service and port have not been defined' do
      let(:yaml) { {} }
      let(:service_name) { 'unknown-service' }

      it 'raises an error' do
        expect { subject.default_value }.to raise_error(/Service '#{service_name}' is unknown, please add to KDK::PortManager::DEFAULT_PORTS_FOR_SERVICES/)
      end
    end

    context 'when a default value is not defined' do
      let(:yaml) { {} }

      it 'returns the default value from PortManager::DEFAULT_PORTS_FOR_SERVICES' do
        expect(subject.default_value).to eq(3000)
      end
    end

    context 'when a default value is defined' do
      let(:yaml) { {} }
      let(:blk) { proc { 456 } }

      it 'returns the defined value' do
        expect(subject.default_value).to eq(456)
      end
    end
  end
end
