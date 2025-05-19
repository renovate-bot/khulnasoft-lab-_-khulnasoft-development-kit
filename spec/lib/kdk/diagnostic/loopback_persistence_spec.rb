# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::LoopbackPersistence do
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
    let(:root_uid) { 42 }
    let(:wheel_gid) { 43 }

    before do
      allow(Process::UID).to receive(:from_name).with('root').and_return(root_uid)
      allow(Process::GID).to receive(:from_name).with('wheel').and_return(wheel_gid)
    end

    it 'passes by default' do
      expect(diagnostic.success?).to be(true)
    end

    context 'when listen_address is 172.16.123.1 and loopback is configured' do
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

      before do
        stub_kdk_yaml <<~YAML
          listen_address: 172.16.123.1
        YAML
        allow(File).to receive(:lstat).and_return(launchdaemon_lstat)
      end

      context 'when daemon plist file has good owner and permission' do
        let(:launchdaemon_lstat) do
          instance_double(File::Stat, uid: root_uid, gid: wheel_gid, mode: 0o644)
        end

        it 'succeeds' do
          expect(diagnostic.success?).to be(true)
        end
      end

      context 'when daemon plist file has wrong owner' do
        let(:launchdaemon_lstat) do
          instance_double(File::Stat, uid: root_uid + 1, gid: wheel_gid - 1, mode: 0o644)
        end

        it 'fails' do
          expect(diagnostic.success?).to be(false)
        end
      end

      context 'when daemon plist file has wrong permissions' do
        let(:launchdaemon_lstat) do
          instance_double(File::Stat, uid: root_uid, gid: wheel_gid, mode: 0o666)
        end

        it 'fails' do
          expect(diagnostic.success?).to be(false)
        end
      end
    end
  end
end
