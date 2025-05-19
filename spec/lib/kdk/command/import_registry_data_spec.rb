# frozen_string_literal: true

RSpec.describe KDK::Command::ImportRegistryData do
  let(:prompt_response) { nil }
  let(:manager) { instance_double(KDK::RegistryDatabaseManager) }

  before do
    allow(KDK::Output).to receive(:error).with("registry.database.enabled must be set to false and registry.read_only_maintenance_enabled must be set to true to run the registry import")
    allow(KDK::Output).to receive(:warn).with("We're about to import the data in your container registry to the new metadata database registry. Once on the metadata registry you must continue to use it. Disabling it after this point causes the registry to lose visibility on all images written to it while the database was active.")
    allow(KDK::Output).to receive(:interactive?).and_return(true)
    allow(KDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(prompt_response)
    allow(KDK::RegistryDatabaseManager).to receive(:new).and_return(manager)
    allow(manager).to receive_messages(reset_registry_database: nil, import_registry_data: nil)
  end

  context 'when the user does not have the correct configs' do
    before do
      # Simulate incorrect configuration by stubbing the config values
      allow(subject).to receive(:config).and_return(
        "registry" => {
          "read_only_maintenance_enabled" => false,
          "database" => {
            "enabled" => true
          }
        }
      )
    end

    it 'does not run' do
      expect(subject).not_to receive(:execute)

      subject.run
    end
  end

  context 'when the user has the correct configs' do
    before do
      # Simulate correct configuration by stubbing the config values
      allow(subject).to receive(:config).and_return(
        "registry" => {
          "read_only_maintenance_enabled" => true,
          "database" => {
            "enabled" => false
          }
        }
      )
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
        expect(manager).to receive(:reset_registry_database).ordered
        expect(manager).to receive(:import_registry_data).ordered

        subject.run
      end
    end
  end
end
