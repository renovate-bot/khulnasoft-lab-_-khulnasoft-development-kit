# frozen_string_literal: true

module KDK
  module Diagnostic
    class GitMaintenance < Base
      TITLE = 'Git Maintenance Recommendation'

      def correct!
        repos_without_git_maintenance.map do |path|
          KDK::Shellout.new(%w[git maintenance start], chdir: path).execute(display_output: false)
        end
      end

      def success?
        repos_without_git_maintenance.empty?
      end

      def detail
        return if success?

        <<~MESSAGE
          We recommend enabling git-maintenance to avoid slowdowns of local git operations like fetch, pull, and checkout.

          To enable it, run `git maintenance start` in each repository:

          #{repos_without_git_maintenance.map { |dir| "git -C #{dir} maintenance start" }.join("\n")}
        MESSAGE
      end

      private

      def repos_without_git_maintenance
        recommended_repo_paths - git_maintenance_repos
      end

      def recommended_repo_paths
        [
          config.kdk_root,
          config.khulnasoft.dir
        ].map(&:to_s)
      end

      def git_maintenance_repos
        @git_maintenance_repos ||= Shellout.new('git config --global --get-all maintenance.repo')
                                           .execute(display_output: false, display_error: false)
                                           .read_stdout
                                           .split("\n")
                                           .filter_map(&:strip)
      end
    end
  end
end
