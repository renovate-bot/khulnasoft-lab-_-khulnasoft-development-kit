# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Firewall do
  include ShelloutHelper

  subject(:diagnostic) { described_class.new }

  let(:output) { 'Firewall is disabled. (State = 0)' }
  let(:team_member) { false }
  let(:platform) { 'linux' }

  before do
    sh = kdk_shellout_double(success?: true, run: output)
    allow_kdk_shellout_command(%w[/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate]).and_return(sh)
    allow(KDK::Telemetry).to receive(:team_member?).and_return(team_member)
    allow(KDK::Machine).to receive(:platform).and_return(platform)
  end

  it 'succeeds by default' do
    expect(diagnostic.success?).to be(true)
  end

  context 'on linux' do
    it 'always succeeds' do
      expect(diagnostic.success?).to be(true)
    end
  end

  context 'when the user is on macos and a team member' do
    let(:team_member) { true }
    let(:platform) { 'darwin' }

    it 'succeeds' do
      expect(diagnostic.success?).to be(true)
    end

    context 'when the firewall is enabled' do
      let(:output) { 'Firewall is enabled. (State = 1)' }

      it 'fails' do
        expect(diagnostic.success?).to be(false)
        expect(diagnostic.detail).to be <<~MESSAGE
          If you are using a managed firewall like SentinelOne or CrowdStrike, we
          recommend disabling the macOS firewall through Settings > Network > Firewall
          to prevent performance problems.
        MESSAGE
      end
    end
  end
end
