# frozen_string_literal: true

RSpec.describe 'rake preflight-checks', :hide_output do
  before(:all) do
    Rake.application.rake_require('tasks/setup')
  end

  let(:checker) { instance_double(KDK::Dependencies::Checker, check_all: nil, error_messages: messages) }

  before do
    allow(KDK::Dependencies::Checker).to receive(:new).and_return(checker)
  end

  context 'when all preflight checks pass' do
    let(:messages) { [] }

    it 'runs all preflight checks' do
      task.execute

      expect(checker).to have_received(:check_all)
    end
  end

  context 'when preflight checks fail' do
    let(:messages) { ['error message'] }

    it 'exits with an error message' do
      expect { task.execute }
        .to output(/error message/).to_stderr
        .and raise_error(RuntimeError, 'Preflight checks failed')

      expect(checker).to have_received(:check_all)
    end
  end
end
