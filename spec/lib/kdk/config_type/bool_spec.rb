# frozen_string_literal: true

RSpec.describe KDK::ConfigType::Bool do
  let(:key) { 'test_key' }
  let(:value) { true }
  let(:yaml) { { key => value } }
  let(:builder) { KDK::ConfigType::Builder.new(key: key, klass: described_class) }

  describe '#parse' do
    ['false', false, 'f', '0', 0].each do |value|
      context "when value is initialized with #{value}" do
        it 'returns false' do
          stub_kdk_yaml(yaml)

          parsed_value = described_class.new(parent: KDK.config, builder: builder).parse(value)

          expect(parsed_value).to be_falsey
        end
      end
    end

    ['true', true, 't', '1', 1].each do |value|
      context "when value is initialized with #{value}" do
        it 'returns true' do
          stub_kdk_yaml(yaml)

          parsed_value = described_class.new(parent: KDK.config, builder: builder).parse(value)

          expect(parsed_value).to be_truthy
        end
      end
    end

    { nil: nil, 'an integer unequal to 0 or 1': 2, 'a string': 'string' }.each do |description, value|
      context "when value is initialized with #{description}" do
        it 'returns false' do
          stub_kdk_yaml(yaml)

          expect do
            described_class.new(parent: KDK.config, builder: builder).parse(value)
          end.to raise_exception(TypeError)
        end
      end
    end
  end
end
