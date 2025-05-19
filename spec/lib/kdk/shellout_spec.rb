# frozen_string_literal: true

RSpec.describe KDK::Shellout do
  let(:command) { 'echo foo' }
  let(:opts) { {} }
  let(:tmp_directory) { File.realpath('/tmp') }

  subject { described_class.new(command, **opts) }

  describe '#args' do
    let(:command_as_array) { %w[echo foo] }

    context 'when command is a String' do
      it 'parses correctly' do
        expect(subject.args).to eq([command])
      end
    end

    context 'when command is an Array' do
      let(:command) { command_as_array }

      it 'parses correctly' do
        expect(subject.args).to eq(command)
      end
    end

    context 'when command is a series of arguments' do
      subject { described_class.new('echo', 'foo') }

      it 'parses correctly' do
        expect(subject.args).to eq(command_as_array)
      end
    end
  end

  describe '#command' do
    let(:command_as_array) { %w[echo foo] }

    it 'returns command as a string' do
      expect(subject.command).to eq('echo foo')
    end
  end

  describe '#exit_code' do
    describe '#run has not yet been executed' do
      it 'returns nil' do
        expect(subject.exit_code).to be_nil
      end
    end

    describe '#run has been executed' do
      before do
        subject.run
      end

      context 'when command is successful' do
        it 'returns 0' do
          expect(subject.exit_code).to be(0)
        end
      end

      context 'when command is not successful' do
        let(:command) { 'echo error 1>&2; exit 1' }

        it 'returns 1' do
          expect(subject.exit_code).to be(1)
        end
      end
    end
  end

  describe '#execute' do
    it 'returns self', :hide_stdout do
      expect(subject.execute).to eq(subject)
    end

    context 'by default' do
      it 'streams the output' do
        expect { subject.execute }.to output("foo\n").to_stdout
      end

      it 'logs the result, including success status, stdout, stderr, and duration', :hide_stdout do
        allow(KDK::Output).to receive(:debug)
        allow(Benchmark).to receive(:realtime).and_yield.and_return(2.0)

        expect(KDK::Output).to receive(:debug).with('result: success?=[true], stdout=[foo], stderr=[], duration=[2.0 seconds]')

        subject.execute
      end
    end

    context 'with display_output: false' do
      it 'does not stream the output' do
        expect { subject.execute(display_output: false) }.not_to output("foo\n").to_stdout
      end
    end

    context 'with display_error: false' do
      let(:command) { 'ls /doesntexist' }

      before do
        # Stubbing ENV crashes in Ruby 3.0: https://bugs.ruby-lang.org/issues/18164
        skip if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.1.0')
      end

      it 'does not display the command failed message' do
        stub_no_color_env('true')

        expect { subject.execute(display_error: false) }.not_to output(%r{ERROR: 'ls /doesntexist' failed.}).to_stderr
        expect { subject.execute(display_error: true) }.to output(%r{ERROR: 'ls /doesntexist' failed.}).to_stderr
      end
    end

    context 'when the command fails completely' do
      shared_examples 'a command that fails' do
        it 'is unsuccessful', :hide_output do
          subject.execute

          expect(subject.success?).to be_falsey
        end

        it 'displays output and errors' do
          expect(KDK::Output).to receive(:print).with(expected_command_stderr_puts, stderr: true)
          expect(KDK::Output).to receive(:error).with(expected_command_error, KDK::Shellout::ShelloutBaseError)

          subject.execute
        end
      end

      shared_examples 'a command that does not retry' do
        it 'does not retry', :hide_output do
          expect(Kernel).not_to receive(:retry)

          subject.execute
        end
      end

      shared_examples 'a command that retries and fails' do
        it 'retries', :hide_output do
          expect(subject).to receive(:sleep).with(2).twice.and_return(true)
          expect(subject).to receive(expected_execute_method).exactly(3).times # 1 for the first run + 2 retries
          expect(subject).to receive(:success?).exactly(6).times.and_return(false)

          expect(KDK::Output).to receive(:error).with("'#{command}' failed. Retrying in 2 secs..", KDK::Shellout::ExecuteCommandFailedError).twice
          expect(KDK::Output).to receive(:error).with("'#{command}' failed.", KDK::Shellout::ExecuteCommandFailedError)

          subject.execute(display_output: display_output, retry_attempts: 2)
        end

        it 'is unsuccessful', :hide_output do
          allow(subject).to receive(:sleep).with(2).twice.and_return(true)
          subject.execute(display_output: display_output, retry_attempts: 2)

          expect(subject.success?).to be_falsey
        end
      end

      context 'when the command does not exist' do
        let(:command) { 'blah' }
        let(:expected_command_stderr_puts) { 'No such file or directory - blah' }
        let(:expected_command_error) { "'blah' failed." }

        it_behaves_like 'a command that fails'
        it_behaves_like 'a command that does not retry'
      end

      context 'when the command does exist, but fails' do
        let(:command) { 'ls /doesntexist' }
        let(:opts) { {} }
        let(:expected_command_stderr_puts) { "ls: cannot access '/doesntexist': No such file or directory\n" }
        let(:expected_command_error) { "'ls /doesntexist' failed." }

        before do
          stderr = StringIO.new(expected_command_stderr_puts)
          stdout = StringIO.new('')
          stdin = instance_double(StringIO, write: '', close: nil)

          allow(stdout).to receive(:wait_readable).and_return(true)
          allow(stderr).to receive(:wait_readable).and_return(true)

          allow(Open3).to receive(:popen3).with({}, command, opts).and_yield(stdin, stdout, stderr, Thread.new { nil })
        end

        it_behaves_like 'a command that fails'
        it_behaves_like 'a command that does not retry'

        context 'with display_output: true' do
          let(:display_output) { true }
          let(:expected_execute_method) { :stream }

          context 'with a retry specified' do
            it_behaves_like 'a command that fails'
            it_behaves_like 'a command that retries and fails'
          end
        end

        context 'with display_output: false' do
          let(:opts) { { err: '/dev/null' } }
          let(:display_output) { false }
          let(:expected_execute_method) { :try_run }

          context 'with a retry specified' do
            it_behaves_like 'a command that fails'
            it_behaves_like 'a command that retries and fails'
          end
        end
      end
    end

    context 'when the command fails once but ultimately succeeds' do
      let(:command) { 'ls /fakedir' }

      it 'fails once but then succeeds', :hide_output do
        allow(subject).to receive(:sleep).with(2).and_return(true)

        expect(subject).to receive(:success?).twice.and_return(false)
        expect(subject).to receive(:success?).twice.and_return(true)

        expect(KDK::Output).to receive(:success).with("'#{command}' succeeded after retry.")

        subject.execute(retry_attempts: 1)
      end
    end
  end

  describe '#stream' do
    let(:task_logger) { nil }

    it 'returns output of shell command', :hide_stdout do
      expect(subject.stream).to eq('foo')
    end

    it 'send output to stdout' do
      expect { subject.stream }.to output("foo\n").to_stdout
    end

    context 'with non UTF-8 output' do
      let(:mixed_encoding) { "🐤🐤🐤🐤\xF0\x9F\x90".dup.force_encoding('ASCII-8BIT') } # rubocop:disable Performance/UnfreezeString -- This doesn't work with frozen_string_literal set
      let(:clean_string) { KDK::Output.ensure_utf8(mixed_encoding) }
      let(:command) { "echo '#{mixed_encoding}'" }

      it 'returns cleaned UTF-8 output of shell command', :hide_stdout do
        expect(subject.stream).to eq(clean_string)
      end

      it 'sends cleaned UTF-8 output to stdout' do
        expect { subject.stream }.to output("#{clean_string}\n").to_stdout
      end
    end

    context 'when chdir: is specified' do
      let(:command) { 'pwd' }
      let(:opts) { { chdir: tmp_directory } }

      it 'changes into the specified directory before executing' do
        expect { expect(subject.stream).to eq(tmp_directory) }.to output("#{tmp_directory}\n").to_stdout
      end
    end

    context 'with a task logger' do
      let(:logger) { nil }

      before do
        allow(Support::Rake::TaskLogger).to receive(:current).and_return(task_logger)
      end

      it 'sets the task logger to nil by default' do
        expect(Support::Rake::TaskLogger).to receive(:set_current!).with(task_logger).twice

        expect { subject.stream }.to output("foo\n").to_stdout
      end

      context 'when the logger is set' do
        let(:task_logger) { instance_double(Support::Rake::TaskLogger) }

        it 'prints to the task logger instead of stdout' do
          buffer = StringIO.new

          expect(Support::Rake::TaskLogger).to receive(:set_current!).with(task_logger).twice
          expect(task_logger).to receive(:file).and_return(buffer)
          expect(task_logger).to receive(:record_input).with("foo\n")

          expect { subject.stream }.not_to output.to_stdout

          expect(buffer.string).to eq("foo\n")
        end
      end
    end
  end

  describe '#readlines' do
    let(:command) { 'seq 10' }

    context 'when limit is not provided' do
      it 'reads all lines' do
        expect(subject.readlines.count).to eq(10)
      end
    end

    context 'when limit is provided' do
      it 'reads the number of lines given' do
        expect(subject.readlines(3).count).to eq(3)
      end
    end
  end

  describe '#run' do
    it 'returns output of shell command' do
      expect(subject.run).to eq('foo')
    end

    context 'when chdir: is specified' do
      let(:command) { 'pwd' }
      let(:opts) { { chdir: tmp_directory } }

      it 'changes into the specified directory before executing' do
        expect(subject.run).to eq(tmp_directory)
      end
    end
  end

  describe '#try_run' do
    let(:command) { 'foo bar' }

    it 'returns empty string' do
      expect(subject.try_run).to eq('')
    end

    it 'does not raise error' do
      expect { subject.try_run }.not_to raise_error
    end

    context 'when chdir: is specified' do
      let(:command) { 'pwd' }
      let(:opts) { { chdir: tmp_directory } }

      it 'changes into the specified directory before executing' do
        expect(subject.try_run).to eq(tmp_directory)
      end
    end
  end

  describe '#read_stdout' do
    before do
      subject.run
    end

    it 'returns stdout of shell command' do
      expect(subject.read_stdout).to eq('foo')
    end
  end

  describe '#read_stderr' do
    let(:command) { 'echo error 1>&2; exit 1' }

    before do
      subject.run
    end

    it 'returns stdout of shell command' do
      expect(subject.read_stderr).to eq('error')
    end
  end

  describe '#success?' do
    describe '#run has not yet been executed' do
      it 'returns false' do
        expect(subject.success?).to be false
      end
    end

    describe '#run has been executed' do
      before do
        subject.run
      end

      context 'when command is successful' do
        it 'returns true' do
          expect(subject.success?).to be true
        end
      end

      context 'when command is not successful' do
        let(:command) { 'echo error 1>&2; exit 1' }

        it 'returns false' do
          expect(subject.success?).to be false
        end
      end
    end
  end
end
