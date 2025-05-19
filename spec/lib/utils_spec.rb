# frozen_string_literal: true

RSpec.describe Utils do
  include ShelloutHelper

  let(:tmp_path) { Dir.mktmpdir('kdk-path') }

  before do
    unstub_find_executable
    stub_env('PATH', tmp_path)
  end

  describe '.find_executable' do
    it 'returns the full path of the executable' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable('dummy')).to eq(executable)
    end

    it 'returns nil when executable cant be found' do
      expect(described_class.find_executable('non-existent')).to be_nil
    end

    it 'also finds by absolute path' do
      executable = create_dummy_executable('dummy')

      expect(described_class.find_executable(executable)).to eq(executable)
    end
  end

  describe '.executable_exist?' do
    it 'returns true if an executable exists in the PATH' do
      create_dummy_executable('dummy')

      expect(described_class.executable_exist?('dummy')).to be_truthy
    end

    it 'returns false when no exectuable can be found' do
      expect(described_class.executable_exist?('non-existent')).to be_falsey
    end
  end

  describe '.executable_exist_via_tooling_manager?' do
    let(:binary_name) { "ruby" }

    %w[mise asdf].each do |tooling_manager|
      context "when #{tooling_manager} is available" do
        before do
          stub_kdk_yaml <<~YAML
            mise:
              enabled: #{tooling_manager == 'mise'}
            asdf:
              opt_out: #{tooling_manager == 'mise'}
          YAML

          allow(Utils).to receive(:executable_exist?).with(tooling_manager).and_return(true)
        end

        it 'returns the tooling manager path to the executable' do
          expect_kdk_shellout_command(%W[#{tooling_manager} which #{binary_name}]).and_return(
            kdk_shellout_double(success?: true).tap { |sh| expect(sh).to receive(:execute).and_return(sh) }
          )

          expect(described_class.executable_exist_via_tooling_manager?(binary_name)).to be(true)
        end
      end
    end

    context 'when no tooling manager is used' do
      before do
        stub_kdk_yaml <<~YAML
            mise:
              enabled: false
            asdf:
              opt_out: true
        YAML
      end

      it 'returns the result of `find_executable`' do
        expect(described_class.executable_exist_via_tooling_manager?(binary_name)).to eq(
          described_class.executable_exist?(binary_name)
        )
      end
    end
  end
end
