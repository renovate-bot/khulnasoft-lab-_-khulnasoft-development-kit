# frozen_string_literal: true

module KDK
  module Project
    class GitWorktree
      DEFAULT_RETRY_ATTEMPTS = 0
      NETWORK_RETRIES = 3

      def initialize(project_name, worktree_path, default_branch, revision, auto_rebase: false)
        @project_name = project_name
        @worktree_path = worktree_path
        @default_branch = default_branch
        @revision = revision
        @auto_rebase = auto_rebase
      end

      def update
        stashed = stash_save

        sh = execute_command(fetch_cmd, retry_attempts: NETWORK_RETRIES)
        unless sh.success?
          KDK::Output.puts(sh.read_stderr, stderr: true)
          KDK::Output.error("Failed to fetch for '#{short_worktree_path}'", sh.read_stderr)
          return false
        end

        result = auto_rebase? ? execute_rebase : execute_checkout_and_pull
      ensure
        stashed ? stash_pop : result
      end

      private

      attr_reader :worktree_path, :default_branch, :revision, :auto_rebase
      alias_method :auto_rebase?, :auto_rebase

      def short_worktree_path
        "#{worktree_path.basename}/"
      end

      def execute_command(command, **args)
        args[:display_output] = false
        args[:retry_attempts] ||= DEFAULT_RETRY_ATTEMPTS

        Shellout.new(command, chdir: worktree_path).execute(**args)
      end

      def execute_rebase
        current_branch_name.empty? ? checkout_revision : rebase
      end

      def execute_checkout_and_pull
        checkout_revision && pull_ff_only
      end

      def checkout_revision(force: false)
        checkout_flags = force ? '-f ' : ''
        action = force ? 'forced checked out' : 'fetched and checked out'
        sh = execute_command("git checkout #{checkout_flags}#{revision}")
        if sh.success?
          KDK::Output.success("Successfully #{action} '#{revision}' for '#{short_worktree_path}'")
          true
        else
          KDK::Output.puts(sh.read_stderr, stderr: true)
          KDK::Output.error("Failed to fetch and check out '#{revision}' for '#{short_worktree_path}'", sh.read_stderr)
          false
        end
      end

      def pull_ff_only
        return true unless revision_is_default?

        command = %w[git pull --ff-only]
        command << remote_name << KDK.config.gitlab.default_branch if khulnasoft_repo?

        sh = execute_command(command, retry_attempts: NETWORK_RETRIES)
        if sh.success?
          KDK::Output.success("Successfully pulled (--ff-only) for '#{short_worktree_path}'")
          true
        else
          KDK::Output.puts(sh.read_stderr, stderr: true)
          KDK::Output.error("Failed to pull (--ff-only) for for '#{short_worktree_path}'", sh.read_stderr)
          false
        end
      end

      def revision_is_default?
        %w[master main].include?(revision)
      end

      def current_branch_name
        @current_branch_name ||= execute_command('git branch --show-current').read_stdout
      end

      def stash_save
        sh = execute_command('git stash save -u')
        sh.success? && sh.read_stdout != 'No local changes to save'
      end

      def stash_pop
        sh = execute_command('git stash pop')

        if sh.success?
          true
        else
          KDK::Output.puts(sh.read_stderr, stderr: true)
          KDK::Output.error("Failed to run `git stash pop` for '#{short_worktree_path}', forcing a checkout to #{revision}. Changes are stored in `git stash`.",
            sh.read_stderr, report_error: false)
          checkout_revision(force: true)
          false
        end
      end

      def fetch_cmd
        if khulnasoft_repo?
          "git fetch --force --tags --prune #{remote_name} #{revision}"
        elsif shallow_clone?
          "git fetch --tags --depth 1 #{remote_name} #{revision}"
        else
          'git fetch --force --all --tags --prune'
        end
      end

      def rebase
        sh = execute_command("git rebase #{ref_remote_branch} -s recursive -X ours --no-rerere-autoupdate")
        if sh.success?
          KDK::Output.success("Successfully fetched and rebased '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'")
          true
        else
          KDK::Output.puts(sh.read_stderr, stderr: true)
          KDK::Output.error("Failed to rebase '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'", sh.read_stderr)
          execute_command('git rebase --abort')
          false # Always send false as the initial 'git rebase' failed.
        end
      end

      def ref_remote_branch
        sh = execute_command("git rev-parse --abbrev-ref #{default_branch}@{upstream}")
        sh.success? ? sh.read_stdout : revision
      end

      def shallow_clone?
        sh = execute_command("git rev-parse --is-shallow-repository")
        sh.success? && sh.read_stdout.chomp == 'true'
      end

      def khulnasoft_repo?
        worktree_path.to_s == KDK.config.gitlab.dir.to_s
      end

      # To avoid fetching from an unnamed remote, we need to determine the remote_name
      # for the given revision. `origin` is usually the remote, but sometimes people
      # modify `origin` to be something else.
      #
      # 1. If this revision is locally checked out (e.g. `master`), determine
      #    which remote is used via `git config branch.#{revision}.remote`.
      #
      # 2. If that doesn't exist, try to determine the remote by matching the URL configured in
      #    `KDK.config.repositories.<project>`.
      #
      # 3. If there is no match, just use `origin`.
      def remote_name
        @remote_name ||= begin
          sh = execute_command(%W[git config branch.#{revision}.remote], display_error: false)

          if sh.success?
            sh.read_stdout.chomp
          else
            project_url = KDK.config.repositories.fetch(@project_name)

            raise "Unknown project: #{@project_name}" unless project_url

            sh = execute_command(%w[git remote -v])

            raise 'Error running `git remote -v`' unless sh.success?

            remotes = parse_git_remotes(sh.read_stdout.chomp)

            remotes[project_url] || 'origin'
          end
        end
      end

      def parse_git_remotes(output)
        # Sample output
        # com     git@gitlab.com:gitlab-community/gitlab-org/gitlab-shell.git (fetch)
        # com     git@gitlab.com:gitlab-community/gitlab-org/gitlab-shell.git (push)
        # origin  https://github.com/khulnasoft-lab/khulnasoft-shell.git (fetch)
        # origin  https://github.com/khulnasoft-lab/khulnasoft-shell.git (push)
        lines = output.split("\n").select { |line| line.include?('(fetch)') }

        lines.filter_map do |line|
          remote_lines = line.split("\t")

          next unless remote_lines.size >= 2

          remote_name = remote_lines[0]
          remote_url = remote_lines[1].split.first

          [remote_url, remote_name] if remote_lines.size >= 2
        end.to_h
      end
    end
  end
end
