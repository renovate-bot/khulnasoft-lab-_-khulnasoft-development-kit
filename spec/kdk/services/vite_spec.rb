# frozen_string_literal: true

RSpec.describe KDK::Services::Vite do
  subject(:service) { described_class.new }

  describe '#name' do
    it { expect(subject.name).to eq 'vite' }
  end

  describe '#command' do
    it 'returns command based on config' do
      expect(subject.command).to match(%(support/exec-cd khulnasoft bundle exec vite dev))
    end
  end

  describe '#enabled?' do
    before do
      webpack = { 'webpack' => { 'enabled' => false } }

      stub_kdk_yaml(config.merge(webpack))
    end

    subject { service.enabled? }

    context 'when enabled' do
      let(:config) { { 'vite' => { 'enabled' => true } } }

      it { is_expected.to be(true) }
    end

    context 'when disabled' do
      let(:config) { { 'vite' => { 'enabled' => false } } }

      it { is_expected.to be(false) }
    end
  end

  describe '#validate!' do
    shared_examples 'validation success' do
      it { expect { subject }.not_to raise_error }
    end

    shared_examples 'validation fails due to config conflict' do
      specify do
        expected_error = <<~ERROR.strip
          Running vite and webpack at the same time is unsupported.
          Consider running `kdk config set webpack.enabled false` to disable webpack
        ERROR

        expect { subject }.to raise_error(KDK::ConfigSettings::UnsupportedConfiguration, expected_error)
      end
    end

    before do
      stub_kdk_yaml(config)
    end

    subject { service.validate! }

    context 'with default config' do
      let(:config) { {} }

      include_examples 'validation success'
    end

    context 'with vite enabled and webpack disabled' do
      let(:config) do
        {
          'vite' => { 'enabled' => true },
          'webpack' => { 'enabled' => false }
        }
      end

      include_examples 'validation success'
    end

    context 'when vite and webpack are enabled' do
      let(:config) do
        {
          'vite' => { 'enabled' => true },
          'webpack' => { 'enabled' => true }
        }
      end

      include_examples 'validation fails due to config conflict'
    end
  end
end
