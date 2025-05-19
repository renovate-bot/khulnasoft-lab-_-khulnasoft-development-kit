# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::OpenBao do
  let(:config) { KDK.config }
  let(:bao) { config.openbao.bin }

  describe '#name' do
    it 'returns openbao' do
      expect(subject.name).to eq('openbao')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run openbao' do
      expect(subject.command).to eq("#{bao} server --config /home/git/kdk/openbao/config.hcl")
    end
  end

  describe '#enabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be(false)
    end
  end

  describe '#ready_message' do
    it 'returns the default ready message' do
      expect(subject.ready_message).to eq('OpenBao is available at http://127.0.0.1:8200.')
    end
  end
end
