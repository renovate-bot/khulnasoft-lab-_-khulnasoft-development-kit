# frozen_string_literal: true

RSpec.describe KDK::Services::OpenLDAP do
  describe '#name' do
    it 'return openldap' do
      expect(subject.name).to eq('openldap')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run OpenLDAP' do
      expect(subject.command).to eq('support/exec-cd gitlab-openldap libexec/slapd -F slapd.d -d2 -h "ldap://127.0.0.1:3890"')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
