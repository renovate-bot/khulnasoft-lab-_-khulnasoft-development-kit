# frozen_string_literal: true

RSpec.describe KDK::ConfigType::Integer do
  let(:value) { nil }
  let(:key) { 'test_key' }
  let(:yaml) { { key => value } }
  let(:builder) { KDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &proc { value }) }

  subject { described_class.new(parent: KDK.config, builder: builder) }

  before do
    stub_pg_bindir
    stub_kdk_yaml(yaml)
  end

  describe '#parse' do
    context 'when value is initialized with an integer' do
      let(:value) { '123' }

      it 'returns parsed value' do
        expect(subject.parse(value)).to eq(123)
      end
    end

    context 'when value is initialized with a string' do
      let(:value) { 'test' }

      it 'raises an exception' do
        expect { subject.parse(value) }.to raise_error(TypeError, "Value 'test' for setting '#{key}' is not a valid integer.")
      end
    end
  end
end
