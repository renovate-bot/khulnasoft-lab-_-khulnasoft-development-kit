# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::DocsKhulnasoftCom do
  describe '#name' do
    it 'returns docs-khulnasoft-com' do
      expect(subject.name).to eq('docs-khulnasoft-com')
    end
  end

  describe '#command' do
    it 'returns the command to run KhulnaSoft Docs' do
      expect(subject.command).to eq('support/exec-cd docs-khulnasoft-com hugo serve --cleanDestinationDir --baseURL http://127.0.0.1 --port 1313 --bind 127.0.0.1')
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('KhulnaSoft Docs is available at http://127.0.0.1:1313.')
    end
  end
end
