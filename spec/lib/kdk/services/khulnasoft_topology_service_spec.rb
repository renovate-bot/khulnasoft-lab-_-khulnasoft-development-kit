# frozen_string_literal: true

RSpec.describe KDK::Services::KhulnasoftTopologyService do
  describe '#name' do
    it { expect(subject.name).to eq('khulnasoft-topology-service') }
  end

  describe '#command' do
    it 'returns the necessary command to run khulnasoft-topology-service' do
      expect(subject.command).to eq('support/exec-cd khulnasoft-topology-service go run . serve')
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('The TopologyService is up and running.')
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject.enabled?).to be(true)
    end
  end
end
