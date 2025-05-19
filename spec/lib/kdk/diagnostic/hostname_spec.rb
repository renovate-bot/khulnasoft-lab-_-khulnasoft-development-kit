# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Hostname do
  describe '#success?' do
    context 'the IP is part of the resolved IPs' do
      before do
        stub_universe(%w[::1 127.0.0.1], 'localhost', '127.0.0.1')
      end

      it { expect(subject.success?).to be true }
    end

    context 'the IP is not part of the resolved IPs' do
      before do
        stub_universe(%w[::1 127.0.0.1], 'kdk.test', '192.168.1.1')
      end

      it { expect(subject.success?).to be false }
    end

    context 'the hostname does not resolve to an IP' do
      before do
        stub_universe([], 'kdk.test', '127.0.0.1')
      end

      it { expect(subject.success?).to be false }
    end

    context 'the hostname is an IP itself' do
      before do
        stub_universe(%w[127.0.0.1], '127.0.0.1', '127.0.0.1')
      end

      it { expect(subject.success?).to be true }
    end
  end

  describe '#detail' do
    context 'if successful' do
      before do
        stub_universe(%w[127.0.0.1], '127.0.0.1', '127.0.0.1')
      end

      it { expect(subject.detail).to be_nil }
    end

    context 'if no hosts found' do
      before do
        stub_universe(%w[], 'kdk.test', '127.0.0.1')
      end

      it { expect(subject.detail).to match 'Could not resolve IP address for the KDK hostname' }
    end

    context 'if IPs do not match' do
      before do
        stub_universe(%w[127.0.0.1 ::1], 'kdk.test', '192.168.12.1')
      end

      it { expect(subject.detail).to match 'You should make sure that the two match.' }
    end
  end

  def stub_universe(resolved_ips, hostname, listen_address)
    allow_any_instance_of(Resolv).to receive(:getaddresses).and_return(resolved_ips)
    allow_any_instance_of(KDK::Config).to receive(:hostname).and_return(hostname)
    allow_any_instance_of(KDK::Config).to receive(:listen_address).and_return(listen_address)
  end
end
