# frozen_string_literal: true

RSpec.describe KDK::ReminderHelper do
  let(:reminder_type) { 'test' }
  let(:fake_cache_dir) { Pathname.new('/fake/cache') }
  let(:reminder_cache_path) { fake_cache_dir.join(KDK::ReminderHelper::REMINDER_DIR_NAME, reminder_type) }
  let!(:now) { DateTime.parse('2025-03-25T19:00:00+00:00').to_time }

  subject { described_class }

  before do
    allow(KDK.config).to receive(:__cache_dir).and_return(fake_cache_dir)
    allow(FileUtils).to receive(:mkdir_p)
    allow(Time).to receive(:now).and_return(now)
  end

  shared_context 'with existing reminder cache path' do |days_ago|
    let(:last_run_time) { (now - (days_ago * 24 * 60 * 60)).iso8601 }

    before do
      allow(File).to receive(:exist?).with(reminder_cache_path).and_return(true)
      allow(File).to receive(:read).with(reminder_cache_path).and_return(last_run_time)
    end
  end

  describe '.should_run_reminder?' do
    it 'creates the reminder directory if it does not exist' do
      expect(FileUtils).to receive(:mkdir_p).with(fake_cache_dir.join(KDK::ReminderHelper::REMINDER_DIR_NAME))
      subject.should_run_reminder?(reminder_type)
    end

    context 'when reminder has never run' do
      before do
        allow(File).to receive(:exist?).with(reminder_cache_path).and_return(false)
      end

      it 'returns true and the cache path' do
        expect(subject.should_run_reminder?(reminder_type)).to be(true)
      end
    end

    context 'when last run was within the default interval (5 days)' do
      include_context 'with existing reminder cache path', 2

      it 'returns false' do
        expect(subject.should_run_reminder?(reminder_type)).to be(false)
      end
    end

    context 'when last run was longer than the default interval (5 days)' do
      include_context 'with existing reminder cache path', 10

      it 'returns true' do
        expect(subject.should_run_reminder?(reminder_type)).to be(true)
      end
    end
  end

  describe '.update_reminder_timestamp!' do
    it 'writes current timestamp to reminder file' do
      expect(File).to receive(:write).with(reminder_cache_path, now.iso8601)
      subject.update_reminder_timestamp!(reminder_type)
    end
  end
end
