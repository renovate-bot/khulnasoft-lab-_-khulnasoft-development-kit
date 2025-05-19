# frozen_string_literal: true

RSpec.describe KDK::Command do
  commands = described_class::COMMANDS

  context 'with declared available command classes' do
    commands.each_value do |command_class_proc|
      it "expects #{command_class_proc.call} to inherit from KDK::Command::BaseCommand directly or indirectly" do
        command_class = command_class_proc.call

        expect(command_class < KDK::Command::BaseCommand).to be_truthy
      end
    end
  end

  describe '.run' do
    validating_config = commands.values.map(&:call).select(&:validate_config?)

    describe 'command invokation' do
      commands.each do |command, command_class_proc|
        command_klass = command_class_proc.call

        context "when invoking 'kdk #{command}' from command-line" do
          let(:argv) { [command] }

          it "delegates execution to #{command_klass}" do
            if validating_config.include?(command_klass)
              expect(described_class).to receive(:validate_config!).and_call_original
            else
              expect(described_class).not_to receive(:validate_config!)
            end

            expect_any_instance_of(command_klass).to receive(:run).and_return(true)

            expect { described_class.run(argv) }.to raise_error(SystemExit)
          end
        end
      end
    end

    context 'with an invalid command' do
      let(:command) { 'rstart' }

      it 'shows a helpful error message' do
        argv = [command]

        expect_output(:warn, message: "rstart is not a KDK command, did you mean - 'kdk restart' or 'kdk start'?")
        expect_output(:puts)
        expect_output(:info, message: "See 'kdk help' for more detail.")

        expect(described_class.run(argv)).to be_falsey
      end
    end
  end

  describe '.validate_config!' do
    let(:raw_yaml) { nil }

    before do
      KDK.instance_variable_set(:@config, nil)
      stub_raw_kdk_yaml(raw_yaml)
    end

    after do
      KDK.instance_variable_set(:@config, nil)
    end

    context 'with valid YAML', :hide_output do
      let(:raw_yaml) { "---\nkdk:\n  debug: true" }

      it 'returns nil' do
        expect(described_class.validate_config!).to be_nil
      end
    end

    shared_examples 'invalid YAML' do |error_message|
      it 'prints an error' do
        expect(KDK::Output).to receive(:error).with("Your KDK configuration is invalid.\n\n", StandardError)
        expect(KDK::Output).to receive(:puts).with(error_message, stderr: true)

        expect { described_class.validate_config! }.to raise_error(SystemExit).and output("\n").to_stderr
      end
    end

    context 'with invalid YAML' do
      let(:raw_yaml) { "---\nkdk:\n  debug" }

      # Ruby 3.3 warns with 'an instance of String'
      # Ruby 3.4 warns with 'fetch'
      it_behaves_like 'invalid YAML', /undefined method (`|')fetch' for ("debug":String|an instance of String)/
    end

    context 'with partially invalid YAML' do
      let(:raw_yaml) { "---\nkdk:\n  debug: fals" }

      it_behaves_like 'invalid YAML', "Value 'fals' for setting 'kdk.debug' is not a valid bool."
    end
  end

  private

  def expect_output(level, message: nil)
    expect(KDK::Output).to receive(level).with(message || no_args)
  end
end
