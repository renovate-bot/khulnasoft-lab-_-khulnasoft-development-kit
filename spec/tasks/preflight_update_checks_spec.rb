# frozen_string_literal: true

RSpec.describe 'rake preflight-update-checks', :hide_output do
  before(:all) do
    Rake.application.rake_require('tasks/setup')
  end

  before do
    allow(KDK::Postgresql).to receive(:new).and_return(postgresql)
    allow(postgresql).to receive(:class).and_return(KDK::Postgresql)
  end

  let(:postgresql) do
    instance_double(
      KDK::Postgresql,
      installed?: true,
      upgrade_needed?: upgrade_needed,
      current_version: '9.6',
      upgrade: nil
    )
  end

  context 'when PostgreSQL needs to be upgraded' do
    let(:upgrade_needed) { true }

    before do
      allow(KDK::Postgresql).to receive(:target_version).and_return('16')
      stub_prompt(
        'y',
        'This will run \'support/upgrade-postgresql\' to back up and upgrade the PostgreSQL data directory. Are you sure? [y/N]'
      )
    end

    context 'when PG_AUTO_UPDATE is set' do
      around do |example|
        original_pg_auto_update = ENV.fetch('PG_AUTO_UPDATE', nil)
        ENV['PG_AUTO_UPDATE'] = '1'
        example.run
        ENV['PG_AUTO_UPDATE'] = original_pg_auto_update
      end

      it 'upgrades PostgreSQL' do
        expect(KDK::Output).to receive(:warn).with("PostgreSQL data directory is version 9.6 and must be upgraded to version 16 before KDK can be updated.\n")
        expect(Kernel).to receive(:sleep).with(10)

        task.execute

        expect(postgresql).to have_received(:upgrade)
        expect(KDK::Output).to have_received(:success).with("Successfully ran 'support/upgrade-postgresql' script!")
      end
    end

    context 'when PG_AUTO_UPDATE is not set' do
      around do |example|
        original_pg_auto_update = ENV.fetch('PG_AUTO_UPDATE', nil)
        ENV.delete('PG_AUTO_UPDATE')
        example.run
        ENV['PG_AUTO_UPDATE'] = original_pg_auto_update
      end

      it 'upgrades PostgreSQL' do
        task.execute

        expect(postgresql).to have_received(:upgrade)
        expect(KDK::Output).to have_received(:success).with("Successfully ran 'support/upgrade-postgresql' script!")
      end
    end
  end

  context 'when PostgreSQL does not need to be upgraded' do
    let(:upgrade_needed) { false }

    it 'does not upgrade PostgreSQL' do
      task.execute

      expect(postgresql).not_to have_received(:upgrade)
    end
  end
end
