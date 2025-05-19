# frozen_string_literal: true

RSpec.describe 'rake kdk:migrate' do
  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  it 'invokes its dependencies' do
    expect(task.prerequisites).to eq(%w[
      migrate:update_telemetry_settings
      migrate:mise
    ])
  end
end

RSpec.describe 'rake kdk:migrate:update_telemetry_settings' do
  let(:enabled) { false }
  let(:is_team_member) { false }
  let(:username) { 'telemetry_user' }

  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  before do
    stub_kdk_yaml(<<~YAML)
      telemetry:
        enabled: #{enabled}
        username: #{username.inspect}
    YAML

    allow(KDK::Telemetry).to receive(:team_member?).and_return(is_team_member)
    allow(KDK.config).to receive(:save_yaml!)
  end

  context 'when telemetry is disabled' do
    let(:enabled) { false }

    context 'and user is not a KhulnaSoft team member' do
      it 'does nothing' do
        expect(KDK::Telemetry).not_to receive(:update_settings)

        task.invoke
      end
    end

    context 'and user is a team member' do
      let(:is_team_member) { true }

      it 'enables telemetry' do
        expect(KDK::Telemetry).to receive(:update_settings).with('y')
        expect(KDK::Output).to receive(:info).with('Telemetry has been automatically enabled for you as a KhulnaSoft team member.')

        task.invoke
      end
    end
  end

  context 'when telemetry is enabled and username is not anonymized' do
    let(:enabled) { true }
    let(:generated_username) { SecureRandom.hex }

    before do
      allow(SecureRandom).to receive(:hex).and_return(generated_username)
    end

    it 'anonymizes the username' do
      expect { task.invoke }.to output(/Telemetry username has been anonymized./).to_stdout
      expect(KDK.config.telemetry.username).not_to eq(username)
      expect(KDK.config.telemetry.username).to match(/^\h{32}$/)
    end
  end
end

RSpec.describe 'rake kdk:migrate:mise' do
  let(:asdf_opt_out) { false }
  let(:mise_enabled) { false }
  let(:is_team_member) { true }
  let(:should_run_reminder) { true }
  let(:is_interactive) { true }
  let(:user_response) { 'n' }
  let(:diagnostic) { instance_double(KDK::Diagnostic::ToolVersionManager) }

  before(:all) do
    Rake.application.rake_require('tasks/kdk')
  end

  before do
    allow(KDK.config).to receive_message_chain(:asdf, :opt_out?).and_return(asdf_opt_out)
    allow(KDK.config).to receive_message_chain(:mise, :enabled).and_return(mise_enabled)
    allow(KDK::Telemetry).to receive(:team_member?).and_return(is_team_member)
    allow(KDK::ReminderHelper).to receive(:should_run_reminder?).with('mise_migration').and_return(should_run_reminder)
    allow(KDK::Output).to receive(:warn)
    allow(KDK::Output).to receive(:puts)
    allow(KDK::Output).to receive(:info)
    allow(KDK::Output).to receive_messages(interactive?: is_interactive, prompt: user_response)
    allow(KDK::Output).to receive(:prompt).and_return(user_response)
    allow(KDK::ReminderHelper).to receive(:update_reminder_timestamp!)
    allow(KDK::Diagnostic::ToolVersionManager).to receive(:new).and_return(diagnostic)
    allow(diagnostic).to receive(:detail).with(:update).and_return('Update message')
    allow(diagnostic).to receive(:correct!)
  end

  context 'when asdf is opted out' do
    let(:asdf_opt_out) { true }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when mise is already enabled' do
    let(:mise_enabled) { true }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when user is not a KhulnaSoft team member' do
    let(:is_team_member) { false }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when reminder should not run' do
    let(:should_run_reminder) { false }

    it 'skips the migration prompt' do
      expect(KDK::Output).not_to receive(:warn)
      expect(KDK::Output).not_to receive(:prompt)

      task.invoke
    end
  end

  context 'when migration should be prompted' do
    context 'when environment is not interactive' do
      let(:is_interactive) { false }

      it 'displays info message and skips the migration prompt' do
        expect(KDK::Output).to receive(:info).with('Skipping mise migration prompt in non-interactive environment.')
        expect(KDK::Output).not_to receive(:prompt)

        task.invoke
      end
    end

    context 'when user accepts the migration' do
      let(:user_response) { 'y' }

      it 'runs the migration' do
        expect(KDK::Output).to receive(:prompt).with('Would you like it to switch to mise now? [y/N]')
        expect(KDK::Output).to receive(:info).with('Great! Running the mise migration now..')
        expect(diagnostic).to receive(:correct!)

        task.invoke
      end
    end

    context 'when user declines the migration' do
      let(:user_response) { 'n' }

      it 'updates the reminder timestamp' do
        expect(KDK::Output).to receive(:prompt).with('Would you like it to switch to mise now? [y/N]')
        expect(KDK::Output).to receive(:info).with("No worries. We'll remind you again in 5 days.")
        expect(KDK::ReminderHelper).to receive(:update_reminder_timestamp!).with('mise_migration')
        expect(diagnostic).not_to receive(:correct!)

        task.invoke
      end
    end
  end
end
