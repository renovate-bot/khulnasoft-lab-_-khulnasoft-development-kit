# frozen_string_literal: true

RSpec.describe KDK::Command::Switch do
  include ShelloutHelper

  let(:branch) { 'cool-feature-woof' }
  let(:rake_success) { true }

  before do
    stub_env('NO_COLOR', '1')
    allow(KDK::Hooks).to receive(:execute_hooks)
    allow(subject).to receive(:run_rake).with('update_branch', branch).and_return(rake_success)
  end

  it 'runs the update_branch rake task' do
    expect { subject.run([branch]) }.to output(/Switched to cool-feature-woof./).to_stdout.and output('').to_stderr
  end

  it 'changes the default_branch only for the current session', :hide_output do
    expect { subject.run([branch]) }.to change { KDK.config.khulnasoft.default_branch }.from('master').to('cool-feature-woof')
  end

  context 'when update_branch fails' do
    let(:rake_success) { false }

    it 'prints an error message' do
      expect { subject.run([branch]) }.to output(/You can try the following that may be of assistance:/).to_stdout.and output(/Failed to switch branches./).to_stderr
    end
  end

  context 'without branch name argument' do
    it 'prints a usage message' do
      expect { subject.run([]) }.to output(/Usage: kdk switch \[BRANCH_NAME\]/).to_stderr
    end
  end
end
