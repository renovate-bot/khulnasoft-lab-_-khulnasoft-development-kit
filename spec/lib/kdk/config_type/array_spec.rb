# frozen_string_literal: true

RSpec.describe KDK::ConfigType::Array do
  let(:key) { 'test_key' }

  describe '#parse' do
    let(:yaml) { { key => value } }
    let(:builder) { KDK::ConfigType::Builder.new(key: key, klass: described_class, **{}, &proc { value }) }

    subject { described_class.new(parent: KDK.config, builder: builder) }

    before do
      stub_pg_bindir
      stub_kdk_yaml(yaml)
    end

    context 'when value is initialized with an integer' do
      let(:value) { '123' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(['123'])
      end
    end

    context 'when value is initialized with a string' do
      let(:value) { 'test' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(['test'])
      end
    end

    context 'when value is initialized with a comma-separated list of integers' do
      let(:value) { '123,456,789' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(%w[123 456 789])
      end
    end

    context 'when value is initialized with a comma-separated list of strings' do
      let(:value) { 'foo,bar,baz' }

      it 'returns an array of strings' do
        expect(subject.parse(value)).to eq(%w[foo bar baz])
      end
    end
  end

  describe '#value' do
    let(:default_value) { nil }
    let(:merge) { false }
    let(:yaml_value) { nil }
    let(:config) do
      defval = default_value # to make variable available in block

      c = Class.new(KDK::ConfigSettings)
      c.array(key, merge: merge, &->(_) { defval })

      c.new(yaml: { key => yaml_value })
    end

    subject(:value) { config.test_key }

    context 'when mergable' do
      let(:merge) { true }
      let(:default_value) { %i[one two] }
      let(:yaml_value) { %i[two three two] }

      it 'avoids user-set duplicates' do
        expect(value).to eq(%i[two three two one])
      end
    end
  end
end
