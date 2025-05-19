# frozen_string_literal: true

require 'spec_helper'
require 'kdk/diagnostic/ruby'

RSpec.describe KDK::Diagnostic::Ruby do
  let(:ruby_diagnostic) { described_class.new }

  describe '#success?' do
    context 'when CXX compiler and Ruby flags are ok' do
      before do
        allow(ruby_diagnostic).to receive_messages(cxx_compiler_ok?: true, ruby_flags_ok?: true)
      end

      it 'returns true' do
        expect(ruby_diagnostic.success?).to be true
      end
    end

    context 'when CXX compiler is not ok' do
      before do
        allow(ruby_diagnostic).to receive_messages(cxx_compiler_ok?: false, ruby_flags_ok?: true)
      end

      it 'returns false' do
        expect(ruby_diagnostic.success?).to be false
      end
    end

    context 'when Ruby flags are not ok' do
      before do
        allow(ruby_diagnostic).to receive_messages(cxx_compiler_ok?: true, ruby_flags_ok?: false)
      end

      it 'returns false' do
        expect(ruby_diagnostic.success?).to be false
      end
    end
  end

  describe '#detail' do
    context 'when successful' do
      before do
        allow(ruby_diagnostic).to receive(:success?).and_return(true)
      end

      it 'returns nil' do
        expect(ruby_diagnostic.detail).to be_nil
      end
    end

    context 'when Ruby flags are not ok' do
      before do
        allow(ruby_diagnostic).to receive_messages(cxx_compiler_ok?: true, ruby_flags_ok?: false)
      end

      it 'returns Ruby flags error message' do
        expect(ruby_diagnostic.detail).to include('Ruby was built without a valid C++ compiler')
      end
    end

    context 'when CXX compiler is not ok' do
      before do
        allow(ruby_diagnostic).to receive_messages(success?: false, cxx_compiler_ok?: false, ruby_flags_ok?: true)
      end

      it 'returns CXX compiler error message' do
        expect(ruby_diagnostic.detail).to include('A legacy XCode Command Line Tools directory was detected')
      end
    end
  end

  describe '#cxx_compiler_ok?' do
    context 'when not on Darwin platform' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-linux')
      end

      it 'returns true' do
        expect(ruby_diagnostic.send(:cxx_compiler_ok?)).to be true
      end
    end

    context 'when on Darwin platform' do
      before do
        stub_const('RUBY_PLATFORM', 'x86_64-darwin21')
      end

      context 'when stale directory exists' do
        before do
          allow(File).to receive(:directory?).with(KDK::Diagnostic::Ruby::XCODE_CLT_STALE_DIRECTORY).and_return(true)
        end

        it 'returns false' do
          expect(ruby_diagnostic.send(:cxx_compiler_ok?)).to be false
        end
      end

      context 'when stale directory does not exist' do
        before do
          allow(File).to receive(:directory?).with(KDK::Diagnostic::Ruby::XCODE_CLT_STALE_DIRECTORY).and_return(false)
        end

        it 'returns true' do
          expect(ruby_diagnostic.send(:cxx_compiler_ok?)).to be true
        end
      end
    end
  end

  describe '#ruby_flags_ok?' do
    context 'when CXX is not "false"' do
      before do
        stub_const('RbConfig::CONFIG', { 'CXX' => 'clang++' })
      end

      it 'returns true' do
        expect(ruby_diagnostic.send(:ruby_flags_ok?)).to be true
      end
    end

    context 'when CXX is "false"' do
      before do
        stub_const('RbConfig::CONFIG', { 'CXX' => 'false' })
      end

      it 'returns false' do
        expect(ruby_diagnostic.send(:ruby_flags_ok?)).to be false
      end
    end
  end
end
