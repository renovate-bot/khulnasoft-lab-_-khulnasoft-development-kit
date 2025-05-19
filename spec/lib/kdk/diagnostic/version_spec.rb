# frozen_string_literal: true

require "spec_helper"

RSpec.describe KDK::Diagnostic::Version do
  let(:version_checker) do
    current_commit = KDK::VersionChecker::GitCommit.new(sha: 'deadbeef', timestamp: DateTime.now - current_commit_age_days)
    latest_main_commit = KDK::VersionChecker::GitCommit.new(sha: 'd06f00d', timestamp: DateTime.now)
    KDK::VersionChecker.new(service_path: KDK.root).tap do |checker|
      allow(checker).to receive_messages(
        current_commit: current_commit,
        latest_main_commit: latest_main_commit
      )
      allow(checker).to receive(:count_commits_between).with(latest_main_commit, current_commit).and_return(10)
      allow(checker).to receive(:count_commits_between).with(current_commit, latest_main_commit).and_return(0)
    end
  end

  before do
    allow(KDK::VersionChecker)
      .to receive(:new)
      .and_return(version_checker)
  end

  describe 'when kdk is not outdated' do
    let(:current_commit_age_days) { 2 }

    describe '#success?' do
      it { expect(subject.success?).to be(true) }
    end

    describe '#detail' do
      it { expect(subject.detail).to be_nil }
    end
  end

  describe 'when kdk is outdated' do
    let(:current_commit_age_days) { 10 }

    describe '#success?' do
      it { expect(subject.success?).to be(false) }
    end

    describe '#detail' do
      it { expect(subject.detail).to eq(<<~MESSAGE) }
        An update for KDK is available.
          - The latest commit of your KDK is 9 days old.
          - Current commit (deadbeef) is 10 commits behind origin/main (d06f00d)
      MESSAGE
    end
  end
end
