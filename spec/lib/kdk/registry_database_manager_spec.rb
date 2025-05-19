# frozen_string_literal: true

RSpec.describe KDK::RegistryDatabaseManager do
  include ShelloutHelper

  let(:kdk_root) { config.kdk_root }
  let(:config) { KDK.config }
  let(:manager) { described_class.new(config) }

  before do
    stub_pg_bindir
    stub_tool_versions
  end

  describe '#import_registry_data' do
    it 'executes the import registry data command' do
      import_command = "#{kdk_root}/support/import-registry"
      expect(manager).to receive(:shellout).with(import_command)

      manager.import_registry_data
    end
  end

  describe '#reset_registry_database' do
    let(:common_command) { ['/usr/local/bin/psql', "--host=#{kdk_root}/postgresql", '--port=5432', '--dbname=gitlabhq_development', '-c'] }
    let(:drop_database_command) { common_command + ['drop database registry_dev'] }
    let(:recreate_database_command) { common_command + ['create database registry_dev'] }
    let(:migrate_database_command) { "#{kdk_root}/support/migrate-registry" }

    before do
      allow_any_instance_of(KDK::Command::Start).to receive(:run).with(['postgresql', '--quiet'])
      allow_any_instance_of(KDK::Command::Stop).to receive(:run).with([])
      allow(manager).to receive(:shellout).with(drop_database_command)
      allow(manager).to receive(:shellout).with(recreate_database_command)
      allow(manager).to receive(:shellout).with(migrate_database_command)
      allow_kdk_shellout_command(drop_database_command, kdk_root)
      allow_kdk_shellout_command(recreate_database_command, kdk_root)
      allow_kdk_shellout_command(migrate_database_command, kdk_root)
    end

    it 'executes the full reset process in order and correctly' do
      expect(manager).to receive(:stop_runit_services).ordered.and_call_original
      expect_any_instance_of(KDK::Command::Stop).to receive(:run).with([])

      expect(manager).to receive(:sleep).with(2).ordered

      expect(manager).to receive(:start_postgresql_service).ordered.and_call_original
      expect_any_instance_of(KDK::Command::Start).to receive(:run).with(['postgresql', '--quiet'])

      expect(manager).to receive(:sleep).with(2).ordered

      expect(manager).to receive(:drop_database).with('registry_dev').ordered.and_call_original
      expect(manager).to receive(:shellout).with(drop_database_command).and_call_original
      expect_shellout_stream(drop_database_command)

      expect(manager).to receive(:recreate_database).with('registry_dev').ordered.and_call_original
      expect(manager).to receive(:shellout).with(recreate_database_command).and_call_original
      expect_shellout_stream(recreate_database_command)

      expect(manager).to receive(:migrate_database).ordered.and_call_original
      expect(manager).to receive(:shellout).with(migrate_database_command).and_call_original
      expect_shellout_stream(migrate_database_command)

      # Run the reset process
      manager.reset_registry_database
    end
  end

  def expect_shellout_stream(command, output: '', success: true)
    double = kdk_shellout_double(stream: output, success?: success)
    expect_kdk_shellout_command(command, chdir: kdk_root).and_return(double)
  end
end
