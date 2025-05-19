# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Environment do
  let(:diagnostic) { described_class.new }

  before do
    stub_env('RUBY_CONFIGURE_OPTS', env_value)
  end

  describe '#success?' do
    subject { diagnostic.success? }

    context 'with some value' do
      let(:env_value) { '--with-jemalloc' }

      it { is_expected.to be_falsey }
    end

    context 'with empty value' do
      let(:env_value) { '' }

      it { is_expected.to be_truthy }
    end

    context 'without value' do
      let(:env_value) { nil }

      it { is_expected.to be_truthy }
    end
  end

  describe '#detail' do
    subject { diagnostic.detail }

    context 'when success?' do
      let(:env_value) { nil }

      it { is_expected.to be_nil }
    end

    context 'when not success?' do
      let(:env_value) { '--with-jemalloc' }

      it { is_expected.to match('RUBY_CONFIGURE_OPTS is configured in your environment') }
    end
  end
end
