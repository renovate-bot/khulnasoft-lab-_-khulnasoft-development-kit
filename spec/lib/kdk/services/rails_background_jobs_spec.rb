# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::RailsBackgroundJobs do
  describe '#name' do
    it 'return rails-background-jobs' do
      expect(subject.name).to eq('rails-background-jobs')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run KhulnaSoft Rails background jobs' do
      expect(subject.command).to eq(%(support/exec-cd khulnasoft bin/background_jobs start_foreground --timeout 10))
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end
end
