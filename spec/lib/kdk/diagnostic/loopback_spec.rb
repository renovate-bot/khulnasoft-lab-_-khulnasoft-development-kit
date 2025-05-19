# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Loopback do
  include ShelloutHelper

  subject(:diagnostic) { described_class.new }

  let(:platform) { 'linux' }

  before do
    sh = kdk_shellout_double(success?: true, run: output)
    allow_kdk_shellout_command(%w[ifconfig lo0]).and_return(sh)
    allow(KDK::Machine).to receive(:platform).and_return(platform)
  end

  context 'on linux' do
    it 'passes by default' do
      expect(diagnostic.success?).to be(true)
    end

    context 'when listen_address is 172.16.123.1' do
      before do
        stub_kdk_yaml <<~YAML
          listen_address: 172.16.123.1
        YAML
      end

      it 'passes' do
        expect(diagnostic.success?).to be(true)
      end
    end
  end

  context 'on macos' do
    let(:team_member) { true }
    let(:platform) { 'darwin' }

    it 'passes by default' do
      expect(diagnostic.success?).to be(true)
    end

    context 'when listen_address is 172.16.123.1' do
      before do
        stub_kdk_yaml <<~YAML
          listen_address: 172.16.123.1
        YAML
      end

      context 'when loopback address is not configured' do
        let(:output) do
          <<~OUTPUT
            lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
              options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
              inet 127.0.0.1 netmask 0xff000000
              inet6 ::1 prefixlen 128
              inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
              nd6 options=201<PERFORMNUD,DAD>
          OUTPUT
        end

        it 'fails' do
          expect(diagnostic.success?).to be(false)
          expect(diagnostic.detail).to eq <<~MESSAGE
            You have configured 172.16.123.1 as listen address, so you
            need to create a loopback interface for KDK to work properly.

            You can do this by running the following command:

              sudo ifconfig lo0 alias 172.16.123.1
          MESSAGE
        end
      end

      context 'when loopback address is configured' do
        let(:output) do
          <<~OUTPUT
            lo0: flags=8049<UP,LOOPBACK,RUNNING,MULTICAST> mtu 16384
              options=1203<RXCSUM,TXCSUM,TXSTATUS,SW_TIMESTAMP>
              inet 127.0.0.1 netmask 0xff000000
              inet6 ::1 prefixlen 128
              inet6 fe80::1%lo0 prefixlen 64 scopeid 0x1
              inet 172.16.123.1 netmask 0xffff0000
              nd6 options=201<PERFORMNUD,DAD>
          OUTPUT
        end

        it 'passes' do
          expect(diagnostic.success?).to be(true)
        end
      end
    end
  end
end
