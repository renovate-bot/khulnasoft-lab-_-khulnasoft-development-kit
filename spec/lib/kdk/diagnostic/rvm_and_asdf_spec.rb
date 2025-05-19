# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::RvmAndAsdf do
  describe '#success?' do
    context 'when RVM and asdf enabled' do
      it 'returns false' do
        stub_rvm_and_asdf_enabled(true)

        expect(subject).not_to be_success
      end
    end

    context 'when asdf is enabled but not RVM' do
      it 'returns true' do
        stub_rvm_and_asdf_enabled(false)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when RVM and asdf enabled' do
      it 'returns a message' do
        stub_rvm_and_asdf_enabled(true)

        expect(subject.detail).to match(/RVM and asdf appear to both be enabled/)
      end
    end

    context 'when asdf is enabled but not RVM' do
      it 'returns no message' do
        stub_rvm_and_asdf_enabled(false)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_rvm_and_asdf_enabled(enabled)
    stub_env('ASDF_DIR', '/tmp/asdf')

    if enabled
      stub_env('rvm_path', '/tmp/rvm')
    else
      stub_env('rvm_path', '')
    end
  end
end
