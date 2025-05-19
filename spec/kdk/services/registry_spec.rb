# frozen_string_literal: true

RSpec.describe KDK::Services::Registry do
  describe '#name' do
    it { expect(subject.name).to eq('registry') }
  end

  describe '#command' do
    it 'returns the correct command' do
      expect(subject.command).to eq('support/exec-cd container-registry bin/registry serve /home/git/kdk/registry/config.yml')
    end
  end
end
