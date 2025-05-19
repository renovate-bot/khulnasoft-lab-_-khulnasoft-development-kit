# frozen_string_literal: true

require 'date'
require 'json'

module KDK
  class VersionChecker
    TIMESTAMP_FORMAT = '%Y-%m-%dT%H:%M:%S%z'
    COMMIT_JSON = '{"sha": "%h", "timestamp": "%ad"}'
    SHOW_COMMIT_CMD = "show -s --format='#{COMMIT_JSON}' --date=format:'#{TIMESTAMP_FORMAT}'".freeze
    DIFF_FORMAT =
      "Current commit (%<current_commit>s) is %<diff>s origin/%<main_branch>s (%<latest_main_commit>s)"

    GitCommit = Data.define(:sha, :timestamp)

    def initialize(service_path:, main_branch: 'main')
      @service_path = service_path
      @main_branch = main_branch
    end

    def diff_message
      return if current_commit.sha == latest_main_commit.sha

      format(
        DIFF_FORMAT,
        current_commit: current_commit.sha,
        diff: commits_diff,
        main_branch: main_branch,
        latest_main_commit: latest_main_commit.sha
      ).strip
    end

    def latest_main_commit
      @latest_main_commit ||= begin
        git("fetch")
        commit(ref: "origin/#{main_branch}")
      end
    end

    def current_commit
      @current_commit ||= commit
    end

    private

    attr_reader :service_path, :main_branch

    def commits_diff
      commits_ahead = count_commits_between(current_commit, latest_main_commit)
      commits_behind = count_commits_between(latest_main_commit, current_commit)

      ahead_message = "#{commits_ahead} commits ahead of" if commits_ahead.positive?
      behind_message = "#{commits_behind} commits behind" if commits_behind.positive?

      [behind_message, ahead_message].compact.join(' and is ')
    end

    def count_commits_between(from_commit, to_commit)
      git("rev-list --count --left-only #{from_commit.sha}...#{to_commit.sha}").to_i
    end

    def commit(ref: nil)
      git("#{SHOW_COMMIT_CMD} #{ref}")
        .then { |string| JSON.parse(string, symbolize_names: true) }
        .then { |hash| hash.merge(timestamp: ::DateTime.strptime(hash[:timestamp], TIMESTAMP_FORMAT)) }
        .then { |hash| GitCommit.new(**hash) }
    end

    def git(cmd)
      Shellout
        .new("git #{cmd}".strip, chdir: service_path)
        .run
    end
  end
end
