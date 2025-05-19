# frozen_string_literal: true

RSpec.describe KDK::Project::GitWorktree do
  include ShelloutHelper

  let(:project_name) { 'some-project' }
  let(:worktree_path) { Pathname.new('/tmp/something') }
  let(:short_worktree_path) { "#{worktree_path.basename}/" }
  let(:default_branch) { 'main' }
  let(:ref_remote_branch) { 'origin/main' }
  let(:revision) { 'main' }
  let(:current_branch_name) { nil }
  let(:auto_rebase) { nil }
  let(:shallow_clone) { nil }
  let(:stash_nothing_to_save) { 'No local changes to save' }
  let(:stash_saved_something) { 'Saved working directory and index state' }
  let(:expected_fetch_type) { shallow_clone ? :shallow : :all }
  let(:infer_remote_name_source) { :local_branch }

  describe '#update' do
    shared_examples "it attempts to update the git worktree for 'feature-branch'" do
      let(:current_branch_name) { 'feature-branch' }

      it 'fetches and updates' do
        expect_update(stash_result: stash_nothing_to_save)
        auto_rebase ? expect_auto_rebase : expect_checkout_and_pull
        expect(subject.update).to be_truthy
      end

      it 'stash saves, fetches, updates and stash pops' do
        expect_update(stash_result: stash_saved_something)
        auto_rebase ? expect_auto_rebase : expect_checkout_and_pull
        expect_shellout('git stash pop')
        expect(subject.update).to be_truthy
      end

      it 'stash saves, fetches, updates, and stash pops fails' do
        stash_pop_stderr = 'failed'

        expect_update(stash_result: stash_saved_something)
        expect(KDK::Output).to receive(:success).with("Successfully forced checked out '#{revision}' for '#{short_worktree_path}'")
        expect(KDK::Output).to receive(:puts).with(stash_pop_stderr, stderr: true)
        expect(KDK::Output).to receive(:error)
          .with("Failed to run `git stash pop` for '#{short_worktree_path}', forcing a checkout to #{revision}. Changes are stored in `git stash`.",
            stash_pop_stderr, report_error: false)
        auto_rebase ? expect_auto_rebase : expect_checkout_and_pull
        expect_shellout('git stash pop', success: false, stderr: stash_pop_stderr)
        expect_shellout("git checkout -f #{revision}")
        expect(subject.update).to be_truthy
      end

      it 'fetch fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, fetch_success: false)
        expect(KDK::Output).to receive(:puts).with("fetch_success: false", stderr: true)
        expect(KDK::Output).to receive(:error).with("Failed to fetch for '#{short_worktree_path}'", 'fetch_success: false')
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something)
        auto_rebase ? expect_auto_rebase(false) : expect_checkout_and_pull(checkout_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something)
        auto_rebase ? expect_auto_rebase(false) : expect_checkout_and_pull(checkout_success: true, pull_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end
    end

    shared_examples "it attempts to update the git worktree when branch is empty (detached head)" do
      let(:current_branch_name) { '' }

      it 'fetches and updates' do
        expect_update(stash_result: stash_nothing_to_save)
        auto_rebase ? expect_just_checkout : expect_checkout_and_pull
        expect(subject.update).to be_truthy
      end

      it 'stash saves, fetches, updates and stash pops' do
        expect_update(stash_result: stash_saved_something)
        auto_rebase ? expect_just_checkout : expect_checkout_and_pull
        expect_shellout('git stash pop')
        expect(subject.update).to be_truthy
      end

      it 'fetch fails, but stash pops' do
        expect_update(stash_result: stash_saved_something, fetch_success: false)
        expect(KDK::Output).to receive(:puts).with("fetch_success: false", stderr: true)
        expect(KDK::Output).to receive(:error).with("Failed to fetch for '#{short_worktree_path}'", "fetch_success: false")
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something)
        auto_rebase ? expect_just_checkout(false) : expect_checkout_and_pull(checkout_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end

      it 'rebase/checkout fails, but stash pops' do
        expect_update(stash_result: stash_saved_something)
        auto_rebase ? expect_just_checkout(false) : expect_checkout_and_pull(checkout_success: true, pull_success: false)
        expect_shellout('git stash pop')
        expect(subject.update).to be_falsey
      end
    end

    context 'when the checkout is shallow' do
      let(:shallow_clone) { true }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like 'it attempts to update the git worktree when branch is empty (detached head)'

      context 'when inferring remote name from git remote -v list' do
        let(:infer_remote_name_source) { :git_remote_list }
        let(:remote_url) { 'https://example.gitlab.com/group/project' }
        let(:git_remote_list) do
          <<~OUT
            com\tgit@gitlab.com:gitlab-community/gitlab-org/gitlab-shell.git (fetch)
            com\tgit@gitlab.com:gitlab-community/gitlab-org/gitlab-shell.git (push)
            test-origin\t#{remote_url} (fetch)
            test-origin\t#{remote_url} (push)
          OUT
        end

        it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
        it_behaves_like 'it attempts to update the git worktree when branch is empty (detached head)'
      end
    end

    context 'when in gitlab-org/gitlab' do
      let(:worktree_path) { KDK.config.kdk_root.join('khulnasoft') }
      let(:expected_fetch_type) { :fast }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like "it attempts to update the git worktree when branch is empty (detached head)"
    end

    context 'when auto_rebase is disabled' do
      let(:auto_rebase) { false }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like "it attempts to update the git worktree when branch is empty (detached head)"
    end

    context 'when auto_rebase is enabled' do
      let(:auto_rebase) { true }

      subject { new_subject }

      it_behaves_like "it attempts to update the git worktree for 'feature-branch'"
      it_behaves_like "it attempts to update the git worktree when branch is empty (detached head)"
    end

    def new_subject
      described_class.new(project_name, worktree_path, default_branch, revision, auto_rebase: auto_rebase)
    end

    def expect_update(stash_result:, fetch_success: true)
      expect_shellout('git stash save -u', stdout: stash_result)
      expect_shellout('git rev-parse --is-shallow-repository', stdout: shallow_clone.to_s) unless expected_fetch_type == :fast

      unless expected_fetch_type == :all
        case infer_remote_name_source
        when :local_branch
          expect_shellout(%W[git config branch.#{default_branch}.remote], args: { display_error: false }, stdout: 'test-origin')
        when :git_remote_list
          expect(KDK.config).to receive(:repositories).and_return({ project_name => remote_url })
          expect_shellout(%W[git config branch.#{default_branch}.remote], args: { display_error: false }, success: false)
          expect_shellout(%w[git remote -v], stdout: git_remote_list)
        end
      end

      command = case expected_fetch_type
                when :fast
                  "git fetch --force --tags --prune test-origin #{revision}"
                when :shallow
                  "git fetch --tags --depth 1 test-origin #{revision}"
                when :all
                  'git fetch --force --all --tags --prune'
                else
                  raise "unknown fetch type, expected one of :fetch_fast, :shallow, :all"
                end

      expect_shellout(command, success: fetch_success, stderr: "fetch_success: #{fetch_success}",
        args: { retry_attempts: described_class::NETWORK_RETRIES })
    end

    def expect_auto_rebase(rebase_success = true)
      expect_shellout('git branch --show-current', stdout: current_branch_name)
      expect_shellout("git rev-parse --abbrev-ref #{default_branch}@{upstream}", stdout: ref_remote_branch)
      stderr = rebase_success ? '' : 'rebase failed'
      expect_shellout("git rebase #{ref_remote_branch} -s recursive -X ours --no-rerere-autoupdate", success: rebase_success, stderr: stderr)
      expect_shellout('git rebase --abort', args: { display_output: false }) unless rebase_success

      if rebase_success
        expect(KDK::Output).to receive(:success).with("Successfully fetched and rebased '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'")
      else
        expect(KDK::Output).to receive(:puts).with(stderr, stderr: true)
        expect(KDK::Output).to receive(:error).with("Failed to rebase '#{default_branch}' on '#{current_branch_name}' for '#{short_worktree_path}'", stderr)
      end
    end

    def expect_checkout_and_pull(checkout_success: true, pull_success: true)
      checkout_stderr = checkout_success ? '' : 'checkout failed'
      expect_shellout("git checkout #{revision}", success: checkout_success, stderr: checkout_stderr)

      if checkout_success
        expect(KDK::Output).to receive(:success).with("Successfully fetched and checked out '#{revision}' for '#{short_worktree_path}'")

        if %w[master main].include?(revision)
          pull_stderr = pull_success ? '' : 'pull failed'
          command = %w[git pull --ff-only]
          command = %w[git pull --ff-only test-origin master] if expected_fetch_type == :fast
          expect_shellout(command, success: pull_success, stderr: pull_stderr,
            args: { retry_attempts: described_class::NETWORK_RETRIES })

          if pull_success
            expect(KDK::Output).to receive(:success).with("Successfully pulled (--ff-only) for '#{short_worktree_path}'")
          else
            expect(KDK::Output).to receive(:puts).with(pull_stderr, stderr: true)
            expect(KDK::Output).to receive(:error).with("Failed to pull (--ff-only) for for '#{short_worktree_path}'", pull_stderr)
          end
        end
      else
        expect(KDK::Output).to receive(:puts).with(checkout_stderr, stderr: true)
        expect(KDK::Output).to receive(:error).with("Failed to fetch and check out '#{revision}' for '#{short_worktree_path}'", checkout_stderr)
      end
    end

    def expect_just_checkout(checkout_success = true)
      checkout_stderr = checkout_success ? '' : 'checkout failed'
      expect_shellout('git branch --show-current', stdout: current_branch_name)
      expect_shellout("git checkout #{revision}", success: checkout_success, stderr: checkout_stderr)

      if checkout_success
        expect(KDK::Output).to receive(:success).with("Successfully fetched and checked out '#{revision}' for '#{short_worktree_path}'")
      else
        expect(KDK::Output).to receive(:puts).with(checkout_stderr, stderr: true)
        expect(KDK::Output).to receive(:error).with("Failed to fetch and check out '#{revision}' for '#{short_worktree_path}'", checkout_stderr)
      end
    end

    def expect_shellout(command, stdout: '', stderr: '', success: true, args: {})
      args[:display_output] ||= false
      args[:retry_attempts] ||= described_class::DEFAULT_RETRY_ATTEMPTS
      shellout_double = kdk_shellout_double(success?: success, read_stdout: stdout, read_stderr: stderr)
      expect_kdk_shellout_command(command, chdir: worktree_path).and_return(shellout_double)
      expect(shellout_double).to receive(:execute).with(**args).and_return(shellout_double)
      shellout_double
    end
  end
end
