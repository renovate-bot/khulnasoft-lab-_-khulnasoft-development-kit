# frozen_string_literal: true

require_relative '../../../lib/git/configure'

RSpec.describe Git::Configure, :hide_stdout do
  describe '#run!' do
    it 'validates an incorrect value' do
      allow($stdin).to receive(:gets).and_return("bleep\n")

      expect { subject.run! }.to output(/Invalid input: bleep/).to_stderr.and raise_error(/Invalid input: bleep/)
    end

    it 'succeeds' do
      expect($stdin).to receive(:gets).and_return("\n").exactly(4).times

      subject.run!
    end
  end
end
