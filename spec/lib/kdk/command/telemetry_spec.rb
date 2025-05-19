# frozen_string_literal: true

RSpec.describe KDK::Command::Telemetry do
  subject(:run) { described_class.new.run([]) }

  before do
    stub_kdk_yaml({})
  end

  context 'when user chooses to disable telemetry' do
    it 'disables telemetry and inform the user' do
      expect($stdin).to receive(:gets).and_return('n')
      expect(KDK::Telemetry).to receive(:update_settings).with('n')

      expect do
        run
      end.to output("#{KDK::Telemetry::PROMPT_TEXT}Telemetry is disabled. No data will be collected.\n").to_stdout
    end
  end

  context 'when user interrupts the prompt' do
    it 'keeps the previous telemetry setting and inform the user' do
      expect($stdin).to receive(:gets).and_raise(Interrupt)
      expect(KDK::Telemetry).not_to receive(:update_settings)

      expect do
        run
      end.to output("#{KDK::Telemetry::PROMPT_TEXT}\nKeeping previous behavior: Telemetry is disabled. No data will be collected.\n").to_stdout
    end
  end
end
