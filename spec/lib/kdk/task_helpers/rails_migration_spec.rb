# frozen_string_literal: true

RSpec.describe KDK::TaskHelpers::RailsMigration, :hide_stdout do
  include ShelloutHelper

  describe '#migrate' do
    let(:shellout_mock) { kdk_shellout_double(success?: true) }
    let(:rails_migration) { described_class.new }

    subject(:migrate) { rails_migration.migrate }

    before do
      allow(shellout_mock).to receive(:execute).and_return(shellout_mock)
      stub_pg_bindir
    end

    context 'database is not in recovery' do
      before do
        allow_any_instance_of(KDK::Postgresql).to receive(:in_recovery?).and_return(false)
      end

      it 'migrates the main database' do
        expect_kdk_shellout.with(array_including('db:migrate'), any_args).and_return(shellout_mock)

        migrate
      end

      it 'does not migrate the Geo database when Geo is a primary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => false })

        allow_kdk_shellout.and_return(shellout_mock)
        expect_no_kdk_shellout.with(array_including('db:migrate:geo'), any_args)

        migrate
      end

      it 'migrates the Geo database when Geo is a secondary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

        expect_kdk_shellout.with(array_including('db:migrate:geo'), any_args).and_return(shellout_mock)

        migrate
      end

      it 'does not migrate the main database when Geo is a secondary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

        allow_kdk_shellout.and_return(shellout_mock)
        expect_no_kdk_shellout.with(array_including('db:migrate'), any_args)

        migrate
      end
    end

    context 'database is in recovery' do
      before do
        allow_any_instance_of(KDK::Postgresql).to receive(:in_recovery?).and_return(true)
      end

      it 'does nothing' do
        expect_no_kdk_shellout

        migrate
      end

      it 'does not migrate the Geo database when Geo is a primary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => false })

        expect_no_kdk_shellout.with(array_including('db:migrate:geo'), any_args)

        migrate
      end

      it 'migrates the Geo database when Geo is a secondary' do
        stub_kdk_yaml('geo' => { 'enabled' => true, 'secondary' => true })

        expect_kdk_shellout.with(array_including('db:migrate:geo'), any_args).and_return(shellout_mock)

        migrate
      end
    end
  end
end
