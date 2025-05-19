# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::OpenBaoProxy do
  let(:config) { KDK.config }
  let(:bao) { config.openbao.bin }

  describe '#name' do
    it 'returns openbao-proxy' do
      expect(subject.name).to eq('openbao-proxy')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run openbao' do
      expect(subject.command).to eq("#{bao} proxy --config /home/git/kdk/openbao/proxy_config.hcl")
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('OpenBaoProxy is available at http://127.0.0.1:8100.')
    end
  end
end
