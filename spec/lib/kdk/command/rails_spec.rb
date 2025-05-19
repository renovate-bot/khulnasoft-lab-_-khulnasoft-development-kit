# frozen_string_literal: true

RSpec.describe KDK::Command::Rails do
  context 'with no extra arguments' do
    it 'aborts execution and returns usage instructions' do
      expect { subject.run([]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr

      expect_no_error_report
    end
  end

  context 'with extra arguments' do
    it 'executes the provided command' do
      command = %w[console]

      expect(subject).to receive(:run).with(command)
      subject.run(command)
    end
  end
end
