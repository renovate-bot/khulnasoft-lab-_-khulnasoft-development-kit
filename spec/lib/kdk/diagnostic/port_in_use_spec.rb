# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::PortInUse do
  include ShelloutHelper

  let(:listen_address) { '127.0.0.1' }
  let(:port) { 3000 }

  subject(:diagnostic) { described_class.new }

  before do
    allow(KDK.config).to receive_messages(listen_address: listen_address, port: port)
    allow(KDK).to receive(:root).and_return(Pathname.new('/path/to/kdk'))
  end

  describe '#success?' do
    context 'when no process is using the port' do
      before do
        lsof_double = kdk_shellout_double(run: '')
        allow_kdk_shellout_command("lsof -ti @#{listen_address}:#{port}", chdir: KDK.root).and_return(lsof_double)
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when port is in use by a KDK process' do
      before do
        lsof_double = kdk_shellout_double(run: "1234\n")
        ps_double = kdk_shellout_double(run: '/path/to/kdk/process')

        allow_kdk_shellout_command("lsof -ti @#{listen_address}:#{port}", chdir: KDK.root).and_return(lsof_double)
        allow_kdk_shellout_command('ps -p 1234 -o args=', chdir: KDK.root).and_return(ps_double)
      end

      it 'returns true' do
        expect(diagnostic.success?).to be true
      end
    end

    context 'when port is in use by an external process' do
      before do
        lsof_double = kdk_shellout_double(run: "1234\n")
        ps_double = kdk_shellout_double(run: '/other/process')

        allow_kdk_shellout_command("lsof -ti @#{listen_address}:#{port}", chdir: KDK.root).and_return(lsof_double)
        allow_kdk_shellout_command('ps -p 1234 -o args=', chdir: KDK.root).and_return(ps_double)
      end

      it 'returns false' do
        expect(diagnostic.success?).to be false
      end
    end
  end

  describe '#detail' do
    context 'when port is available' do
      before do
        allow(diagnostic).to receive(:success?).and_return(true)
      end

      it 'returns nil' do
        expect(diagnostic.detail).to be_nil
      end
    end

    context 'when port is in use' do
      before do
        allow(diagnostic).to receive(:success?).and_return(false)
      end

      it 'returns instructions to fix the port conflict' do
        expected = <<~MSG
          Port #{port} is currently in use by another process.

          This can happen if KDK was previously running and the directory was deleted before stopping it.
          In that case, some processes may still be running in the background and blocking the port.

          To fix this:

            1. Run `lsof -i @#{listen_address}:#{port}` to see which processes are using the port
            2. Use `kill -9 <PID>` to stop them
            3. Run `lsof -i @#{listen_address}:#{port}` again to confirm the port is free

          Once the port is no longer in use, try starting KDK again.
        MSG

        expect(diagnostic.detail).to eq(expected)
      end
    end
  end
end
