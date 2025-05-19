# frozen_string_literal: true

RSpec.describe KDK::Command::Version do
  include ShelloutHelper

  describe '#run' do
    it 'returns the current version' do
      stub_const('KDK::VERSION', 'KhulnaSoft Development Kit 0.2.12')

      current_commit = KDK::VersionChecker::GitCommit.new(sha: 'abc123', timestamp: DateTime.now - 10)
      latest_main_commit = KDK::VersionChecker::GitCommit.new(sha: 'zwk987', timestamp: DateTime.now)
      version_checker = instance_double(
        KDK::VersionChecker,
        current_commit: current_commit,
        latest_main_commit: latest_main_commit,
        diff_message: format(
          KDK::VersionChecker::DIFF_FORMAT,
          current_commit: current_commit.sha,
          latest_main_commit: latest_main_commit.sha,
          main_branch: 'main',
          diff: '10 commits behind'
        ).strip
      )

      allow(KDK::VersionChecker)
        .to receive(:new)
        .and_return(version_checker)

      expect { subject.run }.to output(<<~VERSION).to_stdout
        KhulnaSoft Development Kit 0.2.12 (abc123)
        Current commit (abc123) is 10 commits behind origin/main (zwk987)
      VERSION
    end
  end
end
