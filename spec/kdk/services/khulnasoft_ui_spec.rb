# frozen_string_literal: true

RSpec.describe KDK::Services::KhulnasoftUi do
  describe '#name' do
    it { expect(subject.name).to eq('gitlab-ui') }
  end

  describe '#command' do
    it 'returns the command' do
      expect(subject.command).to eq('support/exec-cd gitlab-ui yarn build --watch')
    end
  end
end
