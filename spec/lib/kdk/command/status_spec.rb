# frozen_string_literal: true

RSpec.describe KDK::Command::Status do
  include ShelloutHelper

  context 'with no extra arguments' do
    context 'when rails_web.enabled is true' do
      it "displays 'KhulnaSoft available' message" do
        allow(KDK.config).to receive(:rails_web?).and_return(true)
        expect(KDK::Output).to receive(:colorize?).and_return(false)

        expect_runit_to_execute(command: 'status')

        expect { subject.run }.to output(/run: redis: \(pid 16722\).+^=> KhulnaSoft available at/m).to_stdout
      end
    end

    context 'when rails_web.enabled is false' do
      it "does not display 'KhulnaSoft available' message" do
        allow(KDK.config).to receive(:rails_web?).and_return(false)

        expect_runit_to_execute(command: 'status')

        expect { subject.run }.not_to output(/KhulnaSoft available at/).to_stdout
      end
    end
  end

  context 'with extra arguments' do
    it 'queries runit for status to specific services only' do
      expect_runit_to_execute(command: 'status', args: ['rails-web'])

      expect { subject.run(%w[rails-web]) }.not_to output(/KhulnaSoft available at/).to_stdout
    end
  end

  def expect_runit_to_execute(command:, args: [])
    sh = kdk_shellout_double
    expect(sh).to receive(:readlines).and_yield("run: #{KDK.config.kdk_root}/services/redis: (pid 16722) 89104s, normally down; run: log: (pid 73434) 94186s")
    expect(Runit).to receive(:sv_shellout).with(command, args).and_return(sh)
  end
end
