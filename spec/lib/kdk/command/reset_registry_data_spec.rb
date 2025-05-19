# frozen_string_literal: true

RSpec.describe KDK::Command::ResetRegistryData do
  let(:manager) { instance_double(KDK::RegistryDatabaseManager) }
  let(:prompt_response) { nil }

  before do
    allow(KDK::Output).to receive(:warn).with("We're about to remove Container Registry PostgreSQL data.")
    allow(KDK::Output).to receive(:interactive?).and_return(true)
    allow(KDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(prompt_response)
    allow(KDK::RegistryDatabaseManager).to receive(:new).and_return(manager)
    allow(manager).to receive(:reset_registry_database).and_return(nil)
  end

  context 'when the user does not accept / aborts the prompt' do
    let(:prompt_response) { 'no' }

    it 'does not run' do
      expect(subject).not_to receive(:execute)

      subject.run
    end
  end

  context 'when the user accepts the prompt' do
    let(:prompt_response) { 'yes' }

    it 'runs' do
      # Expect interactions with the RegistryDatabaseManager instance
      expect(manager).to receive(:reset_registry_database)

      subject.run
    end
  end

  def expect_shellout_stream(command, output: '', success: true)
    double = kdk_shellout_double(stream: output, success?: success)
    expect_kdk_shellout_command(command, chdir: kdk_root).and_return(double)
  end
end
