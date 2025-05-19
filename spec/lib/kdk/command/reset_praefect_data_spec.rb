# frozen_string_literal: true

RSpec.describe KDK::Command::ResetPraefectData do
  include ShelloutHelper

  let(:kdk_root) { Pathname.new('/home/git/kdk') }
  let(:prompt_response) { nil }

  before do
    stub_pg_bindir
    allow(KDK).to receive(:root).and_return(kdk_root)
    allow(KDK::Output).to receive(:warn).with("We're about to remove Praefect PostgreSQL data.")
    allow(KDK::Output).to receive(:interactive?).and_return(true)
    allow(KDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(prompt_response)
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
      stub_tool_versions

      expect(Runit).to receive(:stop).with(quiet: true).and_return(true)
      expect(subject).to receive(:sleep).with(2).and_return(true).ordered
      expect(Runit).to receive(:start).with('postgresql', quiet: true).and_return(true)
      expect(subject).to receive(:sleep).with(2).and_return(true).ordered

      common_command = ['/usr/local/bin/psql', '--host=/home/git/kdk/postgresql', '--port=5432', '--dbname=khulnasofthq_development', '-c']

      drop_database_command = common_command + ['drop database praefect_development']
      expect_shellout_stream(drop_database_command)

      create_database_command = common_command + ['create database praefect_development']
      expect_shellout_stream(create_database_command)

      migrate_database_command = '/home/git/kdk/support/migrate-praefect'
      expect_shellout_stream(migrate_database_command)

      subject.run
    end
  end

  def expect_shellout_stream(command, output: '', success: true)
    double = kdk_shellout_double(stream: output, success?: success)
    expect_kdk_shellout_command(command, chdir: kdk_root).and_return(double)
  end
end
