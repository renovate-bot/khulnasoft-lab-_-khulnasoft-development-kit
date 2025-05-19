# frozen_string_literal: true

require "spec_helper"

RSpec.describe KDK::VersionChecker do
  include ShelloutHelper

  subject(:version_checker) { described_class.new(service_path: KDK.root) }

  describe '#current_commit' do
    it 'returns the current commit on current branch of the given service' do
      allow_kdk_shellout_command("git #{KDK::VersionChecker::SHOW_COMMIT_CMD}", chdir: KDK.root)
        .and_return(kdk_shellout_double(run: '{"sha": "abc123", "timestamp": "2025-01-30T12:00:00+0100"}'))

      expect(version_checker.current_commit.sha).to eq('abc123')
      expect(version_checker.current_commit.timestamp).to eq(DateTime.parse("2025-01-30T12:00:00+0100"))
    end
  end

  describe '#latest_main_commit' do
    it 'returns the latest commit on the main branch of the given service' do
      allow_kdk_shellout_command("git fetch", chdir: KDK.root)
        .and_return(kdk_shellout_double(run: true))

      allow_kdk_shellout_command("git #{KDK::VersionChecker::SHOW_COMMIT_CMD} origin/main", chdir: KDK.root)
        .and_return(kdk_shellout_double(run: '{"sha": "zwk987", "timestamp": "2025-01-31T12:00:00+0100"}'))

      expect(version_checker.latest_main_commit.sha).to eq('zwk987')
      expect(version_checker.latest_main_commit.timestamp).to eq(DateTime.parse("2025-01-31T12:00:00+0100"))
    end
  end

  describe '#diff_message' do
    before do
      allow_kdk_shellout_command("git #{KDK::VersionChecker::SHOW_COMMIT_CMD}", chdir: KDK.root)
        .and_return(kdk_shellout_double(run: '{"sha": "abc123", "timestamp": "2025-01-30T12:00:00+0100"}'))

      allow_kdk_shellout_command("git fetch", chdir: KDK.root)
        .and_return(kdk_shellout_double(run: true))

      allow_kdk_shellout_command("git #{KDK::VersionChecker::SHOW_COMMIT_CMD} origin/main", chdir: KDK.root)
        .and_return(kdk_shellout_double(run: '{"sha": "zwk987", "timestamp": "2025-01-31T12:00:00+0100"}'))

      allow_kdk_shellout_command(%(git rev-list --count --left-only abc123...zwk987), chdir: KDK.root)
        .and_return(kdk_shellout_double(run: '8'))

      allow_kdk_shellout_command(%(git rev-list --count --left-only zwk987...abc123), chdir: KDK.root)
        .and_return(kdk_shellout_double(run: '5'))
    end

    it 'calculates the diff between current commit and latest commit' do
      expect(version_checker.diff_message).to eq(
        'Current commit (abc123) is 5 commits behind and is 8 commits ahead of origin/main (zwk987)'
      )
    end
  end
end
