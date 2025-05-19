# frozen_string_literal: true

RSpec.describe KDK::Command::MeasureUrl do
  include MeasureHelper

  let(:urls) { %w[/explore] }
  let(:docker_running) { nil }

  before do
    stub_tty(false)
  end

  describe '#run' do
    before do
      stub_docker_check(is_running: docker_running)
    end

    context 'when an empty URL array is provided' do
      it 'aborts' do
        expected_error = 'ERROR: Please add URL(s) as an argument (e.g. http://localhost:3000/explore, /explore or https://khulnasoft.com/explore)'
        urls = []

        expect { subject.run(urls) }.to raise_error(expected_error).and output("#{expected_error}\n").to_stderr
        expect_no_error_report
      end
    end

    include_examples 'it checks if Docker and KDK are running', %w[/explore]

    context 'when Docker and KDK are running' do
      include_context 'Docker and KDK are running'

      context 'with a single url' do
        include_examples 'runs sitespeed via Docker', 'linux', 'urls', %w[/explore]
        include_examples 'runs sitespeed via Docker', 'macOS', 'urls', %w[/explore]
      end
    end
  end
end
