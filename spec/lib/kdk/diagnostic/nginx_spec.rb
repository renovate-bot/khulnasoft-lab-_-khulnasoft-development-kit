# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Nginx do
  include ShelloutHelper

  subject(:nginx_diagnostic) { described_class.new }

  let(:config) { instance_double(KDK::Config) }
  let(:shellout) { kdk_shellout_double }

  before do
    allow(KDK).to receive(:config).and_return(config)
    allow_kdk_shellout.and_return(shellout)
    allow(config).to receive_messages(
      find_executable!: 'nginx',
      kdk_root: '/home/kdk'
    )
    allow(shellout).to receive(:execute)
  end

  describe '#success?' do
    subject(:success_call) { nginx_diagnostic.success? }

    context 'when nginx is not enabled' do
      before do
        allow(config).to receive_message_chain(:nginx, :enabled?).and_return(false)
      end

      it 'skips the check' do
        allow(nginx_diagnostic).to receive(:test_cmd).and_raise('Should not be called!')

        expect(success_call).to be(true)
      end
    end

    context 'when nginx is enabled' do
      before do
        allow(config).to receive_message_chain(:nginx, :enabled?).and_return(true)
      end

      context 'when command executes with exit code 0' do
        before do
          allow(shellout).to receive(:success?).and_return(true)
        end

        it 'returns true' do
          expect(success_call).to be(true)
        end
      end

      context 'when command executes with exit code 1' do
        before do
          allow(shellout).to receive(:success?).and_return(false)
        end

        it 'returns false' do
          expect(success_call).to be(false)
        end
      end
    end
  end

  describe '#detail' do
    subject(:detail) { nginx_diagnostic.detail }

    context 'when doctor command is successful' do
      before do
        allow(config).to receive_message_chain(:nginx, :enabled?).and_return(false)
      end

      it { is_expected.to be_nil }
    end

    context 'when doctor command is unsuccessful' do
      before do
        allow(config).to receive_message_chain(:nginx, :enabled?).and_return(true)
        allow(shellout).to receive_messages(
          success?: false,
          read_stdout: 'nginx: example stdout of -t',
          read_stderr: 'nginx: example stderr of -t'
        )
      end

      it 'includes stdout and stderr from nginx -t command' do
        expect(detail).to include('example stdout')
        expect(detail).to include('example stderr')
      end
    end
  end
end
