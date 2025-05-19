# frozen_string_literal: true

RSpec.describe KDK::Command::Pristine do
  include ShelloutHelper

  let(:config) { KDK.config }

  subject { described_class.new }

  describe '#run' do
    before do
      stub_tty(false)
    end

    context 'when a command fails' do
      it 'displays an error and returns false', :hide_stdout do
        expect(Runit).to receive(:stop).with(quiet: true).and_return(false)

        expect(KDK::Output).to receive(:error).with("Failed to run 'kdk pristine' - Had an issue with 'kdk_stop'.", RuntimeError)

        expect(subject.run).to be(false)
      end
    end

    context 'when all commands succeed' do
      it 'displays an informational message and returns true', :hide_stdout do
        shellout_double = kdk_shellout_double(stream: nil, success?: true)

        # kdk_stop
        expect(Runit).to receive(:stop).with(quiet: true).and_return(true)

        # kdk_tmp_clean
        expect_kdk_shellout_command(described_class::GIT_CLEAN_TMP_CMD).and_return(shellout_double)

        # kdk_bundle
        expect_kdk_shellout_command(subject.bundle_install_cmd).and_return(shellout_double)
        expect_kdk_shellout_command(described_class::BUNDLE_PRISTINE_CMD).and_return(shellout_double)

        # reset_configs
        expect_kdk_shellout_command(described_class::RESET_CONFIGS_CMD).and_return(shellout_double)

        # khulnasoft_bundle
        expect_kdk_shellout_command(subject.bundle_install_cmd, chdir: config.gitlab.dir).and_return(shellout_double)
        expect_kdk_shellout_command(described_class::BUNDLE_PRISTINE_CMD, chdir: config.gitlab.dir).and_return(shellout_double)

        # khulnasoft_tmp_clean
        expect_kdk_shellout_command(described_class::GIT_CLEAN_TMP_CMD, chdir: config.gitlab.dir).and_return(shellout_double)

        # khulnasoft_yarn_clean
        expect_kdk_shellout_command(described_class::YARN_CLEAN_CMD, chdir: config.gitlab.dir).and_return(shellout_double)

        expect(KDK::Output).to receive(:success).with("Successfully ran 'kdk pristine'!")

        expect(subject.run).to be(true)
      end
    end
  end

  describe '#bundle_install_cmd' do
    it 'returns the default bundle install command' do
      allow(config).to receive(:restrict_cpu_count).and_return(6)

      expect(subject.bundle_install_cmd).to eq('bundle install --jobs 6 --quiet')
    end
  end
end
