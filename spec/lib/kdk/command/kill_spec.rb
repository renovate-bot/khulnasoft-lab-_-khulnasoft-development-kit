# frozen_string_literal: true

RSpec.describe KDK::Command::Kill, :hide_stdout do
  include ShelloutHelper

  let!(:root) { KDK.root }

  context "when there's no runsv processes" do
    it 'displays an informational message and returns' do
      stub_runsv_processes_to_kill('')

      expect(KDK::Output).to receive(:info).with('No runsv processes detected.')
      expect(subject).not_to receive(:kill_runsv_processes!)

      expect(subject.run).to be(true)
    end
  end

  context 'prompt behavior' do
    let(:runsv_processes_to_kill_output) { 'runsv process output here' }

    before do
      stub_runsv_processes_to_kill(runsv_processes_to_kill_output)
      allow(KDK::Output).to receive(:warn).with("You're about to kill the following runsv processes:\n\n")
      allow(KDK::Output).to receive(:puts).with("#{runsv_processes_to_kill_output}\n\n")
      allow(KDK::Output).to receive(:info).with("This command will stop all your KDK instances and any other process started by runit.\n\n")
    end

    context 'when the user does not accept / aborts the prompt' do
      it 'does not run' do
        stub_prompt('no')

        expect(subject).not_to receive(:kill_runsv_processes!)

        expect(subject.run).to be(true)
      end
    end

    context 'when the user accepts the prompt' do
      it 'runs' do
        stub_prompt('yes')

        expect(subject).to receive(:kill_runsv_processes!).and_return(true)
        expect(KDK::Output).to receive(:success).with("All 'runsv' processes have been terminated.")

        expect(subject.run).to be(true)
      end
    end

    context 'when user accepts by flag' do
      it "doesn't prompt" do
        expect(subject).to receive(:kill_runsv_processes!).and_return(true)

        expect(KDK::Output).not_to receive(:prompt)
        expect(KDK::Output).to receive(:success)

        expect(subject.run(['-y'])).to be(true)
      end
    end
  end

  context 'kill behavior' do
    let(:initial_runsv_processes_to_kill_output) { 'runsv process output here' }

    before do
      stub_runsv_processes_to_kill(initial_runsv_processes_to_kill_output, '')
      allow(subject).to receive(:continue?).and_return(true)
      stub_wait
    end

    it "runs 'kdk stop'" do
      expect(KDK::Output).to receive(:info).with("Running 'kdk stop' to be sure..")
      expect(Runit).to receive(:stop).and_return(true)
      expect(KDK::Output).to receive(:success).with("All 'runsv' processes have been terminated.")

      expect(subject.run).to be(true)
    end

    it "runs 'pkill runsv'" do
      allow(subject).to receive(:kdk_stop_succeeded?).and_return(false)
      stub_pkill('pkill runsv')

      expect(subject.run).to be(true)
    end

    it "runs 'pkill -9 runsv'" do
      allow(subject).to receive_messages(kdk_stop_succeeded?: false, pkill_runsv_succeeded?: false)
      stub_pkill('pkill -9 runsv')

      expect(subject.run).to be(true)
    end

    context 'when all attempts to kill have failed' do
      it 'lists the runsv processes that are still running' do
        allow(subject).to receive(:kill_runsv_processes!).and_return(false)

        expect(KDK::Output).to receive(:error).with("Failed to kill all 'runsv' processes.")

        expect(subject.run).to be(false)
      end
    end
  end

  def stub_pkill(command)
    shellout_double = kdk_shellout_double(try_run: '', exit_code: 0)
    expect(KDK::Output).to receive(:info).with("Running '#{command}'..")
    expect_kdk_shellout_command(command).and_return(shellout_double)
    expect(KDK::Output).to receive(:success).with("All 'runsv' processes have been terminated.")
  end

  def stub_runsv_processes_to_kill(*result)
    shellout_double = kdk_shellout_double
    allow_kdk_shellout_command('ps -ef | grep "[r]unsv"').and_return(shellout_double)
    allow(shellout_double).to receive(:try_run).and_return(*result)
  end

  def stub_wait
    allow(KDK::Output).to receive(:info).with('Giving runsv processes 5 seconds to terminate..')
    allow(subject).to receive(:sleep).with(5).and_return(true)
  end
end
