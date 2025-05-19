# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Workerd do
  include ShelloutHelper

  let(:maintenance_repos) { [] }
  let(:pids) { [] }

  before do
    stub_kdk_yaml({})

    allow_kdk_shellout_command(%w[ps x]).once do
      output = pids.map { |pid| "#{pid}   ??  S      0:01.04 #{KDK.config.kdk_root}/khulnasoft-http-router/node_modules/@cloudflare/workerd-darwin-arm64/bin/workerd serve" }.join("\n")
      kdk_shellout_double(run: output)
    end
  end

  describe '#success?' do
    it { expect(subject.success?).to be(true) }

    context 'when khulnasoft-http-router is running' do
      let(:pids) { [1234, 1235] }

      it { expect(subject.success?).to be(true) }
    end

    context 'when there are more than 2 workerd processes' do
      let(:pids) { [1234, 1235, 1236] }

      it { expect(subject.success?).to be(false) }
    end
  end

  describe '#detail' do
    it { expect(subject.detail).to be_nil }

    context 'when khulnasoft-http-router is running' do
      let(:pids) { [1234, 1235] }

      it { expect(subject.detail).to be_nil }
    end

    context 'when there are more than 2 workerd processes' do
      let(:pids) { [1234, 1235, 1236] }

      it 'returns a message' do
        expect(subject.detail).to eq(
          <<~MESSAGE
          There are 3 `workerd` processes running but there should only be 2 running at max.

          If your KDK has trouble booting, run the following command to kill all `workerd` processes:

          kill -9 1234 1235 1236
        MESSAGE
        )
      end
    end
  end
end
