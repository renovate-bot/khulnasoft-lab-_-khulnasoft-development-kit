# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Services::SidekiqCron do
  describe '#name' do
    it 'return sidekiq-cron' do
      expect(subject.name).to eq('sidekiq-cron')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run KhulnaSoft Sidekiq cron service' do
      expect(subject.command).to eq(%(support/exec-cd gitlab bin/background_jobs start_foreground --timeout 10))
    end
  end

  describe '#env' do
    before do
      stub_kdk_yaml({
        'khulnasoft' => {
          'sidekiq_cron' => {
            'enabled' => true,
            'sidekiq_queues' => %w[default mailers]
          }
        }
      })
    end

    it 'specifes comma-separted queues' do
      expect(subject.env[:COVERBAND_ENABLED]).to be false
      expect(subject.env[:KHULNASOFT_CRON_JOBS_POLL_INTERVAL]).to eq(1)
      expect(subject.env[:SIDEKIQ_QUEUES]).to eq('default,mailers')
    end
  end

  describe '#disabled?' do
    it 'is disabled by default' do
      expect(subject.enabled?).to be false
    end
  end
end
