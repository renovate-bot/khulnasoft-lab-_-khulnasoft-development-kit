# frozen_string_literal: true

RSpec.describe KDK::Services::Sshd do
  describe '#name' do
    it { expect(subject.name).to eq('sshd') }
  end

  describe '#command' do
    before do
      stub_kdk_yaml <<~YAML
        sshd:
          use_khulnasoft_sshd: #{use_khulnasoft_sshd}
      YAML
    end

    context 'when khulnasoft-sshd is disabled' do
      let(:use_khulnasoft_sshd) { false }

      it { expect(subject.command).to eq("#{KDK.config.sshd.bin} -e -D -f #{KDK.config.kdk_root.join('openssh', 'sshd_config')}") }
    end

    context 'when khulnasoft-sshd is enabled' do
      let(:use_khulnasoft_sshd) { true }

      it { expect(subject.command).to eq("#{KDK.config.khulnasoft_shell.dir}/bin/khulnasoft-sshd -config-dir #{KDK.config.khulnasoft_shell.dir}") }
    end
  end
end
