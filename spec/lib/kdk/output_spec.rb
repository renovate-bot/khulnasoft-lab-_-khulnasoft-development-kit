# frozen_string_literal: true

RSpec.describe KDK::Output do
  describe '.ensure_utf8' do
    context 'when input is nil' do
      it 'returns an empty string' do
        expect(described_class.ensure_utf8(nil)).to eq('')
      end
    end

    context 'when input is not a string' do
      it 'returns the input unchanged' do
        expect(described_class.ensure_utf8(123)).to eq(123)
      end
    end

    context 'when input is already UTF-8' do
      it 'returns the string unchanged' do
        expect(described_class.ensure_utf8('abcde')).to eq('abcde')
      end
    end

    context 'when input is not a UTF-8 string' do
      it 'encodes the string to UTF-8' do
        ascii_string = 'abcde'.encode('ASCII-8BIT')

        expect(described_class.ensure_utf8(ascii_string).encoding).to eq(Encoding::UTF_8)
      end
    end

    context 'when input is a frozen string' do
      it 'duplicates and encodes the string to UTF-8' do
        frozen_string = 'abcde'.encode('ASCII-8BIT').freeze

        result = described_class.ensure_utf8(frozen_string)
        expect(result.encoding).to eq(Encoding::UTF_8)
        expect(result).not_to be_frozen
      end
    end
  end

  describe '.print' do
    context 'by default' do
      it 'prints to stdout' do
        expect { described_class.print('test') }.to output('test').to_stdout
      end
    end

    context 'with stderr: true' do
      it 'prints to stderr' do
        expect { described_class.print('test', stderr: true) }.to output('test').to_stderr
      end
    end

    context 'when the rake task logger is set' do
      let(:task) { instance_double(Rake::Task, name: 'test task') }

      before do
        logger = Support::Rake::TaskLogger.from_task(task)
        allow(logger).to receive(:create_latest_symlink!)
        Support::Rake::TaskLogger.set_current!(logger)
      end

      after do
        Support::Rake::TaskLogger.set_current!(nil)
      end

      context 'by default' do
        it 'prints to the file' do
          buffer = StringIO.new
          expect(Support::Rake::TaskLogger.current).to receive(:file).and_return(buffer)
          expect { described_class.print('test') }.not_to output.to_stdout
        end
      end

      context 'with stderr: true' do
        it 'prints to stderr' do
          buffer = StringIO.new
          expect(Support::Rake::TaskLogger.current).to receive(:file).and_return(buffer)
          expect { described_class.print('test', stderr: true) }.not_to output.to_stderr
        end
      end
    end
  end

  describe '.puts' do
    context 'by default' do
      it 'puts to stdout' do
        expect { described_class.puts('test') }.to output("test\n").to_stdout
      end
    end

    context 'with stderr: true' do
      it 'puts to stdout' do
        expect { described_class.puts('test', stderr: true) }.to output("test\n").to_stderr
      end
    end

    context 'when the rake task logger is set' do
      let(:task) { instance_double(Rake::Task, name: 'test task') }

      before do
        logger = Support::Rake::TaskLogger.from_task(task)
        allow(logger).to receive(:create_latest_symlink!)
        Support::Rake::TaskLogger.set_current!(logger)
      end

      after do
        Support::Rake::TaskLogger.set_current!(nil)
      end

      context 'by default' do
        it 'prints to the file' do
          buffer = StringIO.new
          expect(Support::Rake::TaskLogger.current).to receive(:file).and_return(buffer)
          expect { described_class.puts('test') }.not_to output.to_stdout
        end
      end

      context 'with stderr: true' do
        it 'prints to stderr' do
          buffer = StringIO.new
          expect(Support::Rake::TaskLogger.current).to receive(:file).and_return(buffer)
          expect { described_class.puts('test', stderr: true) }.not_to output.to_stderr
        end
      end
    end
  end

  describe '.notice' do
    it 'puts formatted message to stdout' do
      stub_no_color_env('')

      expect { described_class.notice('test') }.to output("=> test\n").to_stdout
    end
  end

  describe '.notice_format' do
    it 'returns formatted message' do
      expect(described_class.notice_format('test')).to eq('=> test')
    end
  end

  describe '.info' do
    it 'puts to stdout' do
      stub_no_color_env('')

      expect { described_class.info('test') }.to output("\u2139\ufe0f  test\n").to_stdout
    end
  end

  describe '.success' do
    context "when we're not a tty" do
      it 'puts to stdout' do
        stub_tty(false)

        expect { described_class.success('test') }.to output("test\n").to_stdout
      end
    end

    context 'when we are a tty' do
      context 'when NO_COLOR=true is not defined' do
        it 'puts to stdout' do
          stub_tty(true)
          stub_no_color_env('')

          expect { described_class.success('test') }.to output("\u2705\ufe0f test\n").to_stdout
        end
      end

      context 'when NO_COLOR=true is defined' do
        it 'puts to stdout minus icon and colorization' do
          stub_no_color_env('true')

          expect { described_class.success('test') }.to output("test\n").to_stdout
        end
      end
    end
  end

  describe '.warn' do
    context "when we're not a tty" do
      it 'puts to stderr minus icon and colorization' do
        stub_tty(false)

        expect { described_class.warn('test') }.to output("WARNING: test\n").to_stderr
      end
    end

    context 'when we are a tty' do
      context 'when NO_COLOR=true is not defined' do
        it 'puts to stderr' do
          stub_no_color_env('')

          expect { described_class.warn('test') }.to output("\u26a0\ufe0f  \e[33mWARNING\e[0m: test\n").to_stderr
        end
      end

      context 'when NO_COLOR=true is defined' do
        it 'puts to stderr minus icon and colorization' do
          stub_no_color_env('true')

          expect { described_class.warn('test') }.to output("WARNING: test\n").to_stderr
        end
      end
    end
  end

  describe '.debug' do
    before do
      stub_tty(false)
      stub_kdk_debug(debug_enabled)
    end

    context 'when debug is not enabled' do
      let(:debug_enabled) { false }

      it 'outputs nothing' do
        expect { described_class.debug('test') }.not_to output("DEBUG: test\n").to_stderr
      end
    end

    context 'when debug is enabled' do
      let(:debug_enabled) { true }

      context "when we're not a tty" do
        it 'puts to stderr minus icon and colorization' do
          expect { described_class.debug('test') }.to output("DEBUG: test\n").to_stderr
        end
      end

      context 'when we are a tty' do
        context 'when NO_COLOR=true is not defined' do
          it 'puts to stderr' do
            stub_no_color_env('')

            expect { described_class.debug('test') }.to output("\u26CF\ufe0f  \e[34mDEBUG\e[0m: test\n").to_stderr
          end

          it 'returns a UTF-8 message that cleans up invalid characters' do
            stub_no_color_env('')

            msg = "🐤🐤🐤🐤\xF0\x9F\x90".dup.force_encoding('ASCII-8BIT') # rubocop:disable Performance/UnfreezeString -- This doesn't work with frozen_string_literal set

            expect { described_class.debug(msg) }.to output("\u26CF\ufe0f  \e[34mDEBUG\e[0m: 🐤🐤🐤🐤�\n").to_stderr
          end
        end

        context 'when NO_COLOR=true is defined' do
          it 'puts to stderr minus icon and colorization' do
            stub_no_color_env('true')

            expect { described_class.debug('test') }.to output("DEBUG: test\n").to_stderr
          end
        end
      end
    end
  end

  describe '.format_error' do
    context "when we're not a tty" do
      it 'puts to stderr minus icon and colorization' do
        stub_tty(false)

        expect(described_class.format_error('test')).to eq('ERROR: test')
      end
    end

    context 'when we are a tty' do
      context 'when NO_COLOR=true is not defined' do
        it 'puts to stderr' do
          stub_no_color_env('')

          expect(described_class.format_error('test')).to eq("\u274C\ufe0f \e[31mERROR\e[0m: test")
        end
      end

      context 'when NO_COLOR=true is defined' do
        it 'puts to stderr minus icon and colorization' do
          stub_no_color_env('true')

          expect(described_class.format_error('test')).to eq('ERROR: test')
        end
      end
    end
  end

  describe '.error' do
    context "when we're not a tty" do
      it 'puts to stderr minus icon and colorization' do
        stub_tty(false)

        expect { described_class.error('test') }.to output("ERROR: test\n").to_stderr
      end
    end

    context 'when we are a tty' do
      context 'when NO_COLOR=true is not defined' do
        it 'puts to stderr' do
          stub_no_color_env('')

          expect { described_class.error('test') }.to output("\u274C\ufe0f \e[31mERROR\e[0m: test\n").to_stderr
        end
      end

      context 'when NO_COLOR=true is defined' do
        it 'puts to stderr minus icon and colorization' do
          stub_no_color_env('true')

          expect { described_class.error('test') }.to output("ERROR: test\n").to_stderr
        end
      end
    end

    it 'reports message to telemetry', :hide_stdout do
      described_class.error('test')

      expect(KDK::Telemetry).to have_received(:capture_exception).with('test')
    end

    it 'reports exception to telemetry', :hide_stdout do
      exception = StandardError.new
      described_class.error('test', exception)

      expect(KDK::Telemetry).to have_received(:capture_exception).with(exception)
    end

    it 'skips report if disabled', :hide_stdout do
      described_class.error('test', report_error: false)

      expect_no_error_report
    end
  end

  describe '.abort' do
    context "when we're not a tty" do
      it 'puts to stderr minus icon and colorization' do
        stub_tty(false)

        expect { described_class.abort('test') }.to raise_error(/test/).and output("ERROR: test\n").to_stderr
      end
    end

    context 'when we are a tty' do
      context 'when NO_COLOR=true is not defined' do
        it 'puts to stderr' do
          stub_no_color_env('')

          expect { described_class.abort('test') }.to raise_error(/test/).and output("\u274C\ufe0f \e[31mERROR\e[0m: test\n").to_stderr
        end
      end

      context 'when NO_COLOR=true is defined' do
        it 'puts to stderr minus icon and colorization' do
          stub_no_color_env('true')

          expect { described_class.abort('test') }.to raise_error(/test/).and output("ERROR: test\n").to_stderr
        end
      end
    end

    it 'reports message to telemetry' do
      message = 'test'
      expect { described_class.abort(message) }
        .to raise_error(SystemExit).and output.to_stderr

      expect(KDK::Telemetry).to have_received(:capture_exception).with(message)
    end

    it 'reports exception to telemetry' do
      message = 'test'
      exception = StandardError.new

      expect { described_class.abort(message, exception) }
        .to raise_error(SystemExit).and output.to_stderr

      expect(KDK::Telemetry).to have_received(:capture_exception).with(exception)
    end

    it 'skips report if disabled' do
      expect { described_class.abort('test', report_error: false) }
        .to raise_error(SystemExit).and output.to_stderr

      expect_no_error_report
    end
  end

  describe '.color' do
    it 'returns a color for index' do
      expect(described_class.color(0)).to eq('31')
    end
  end

  describe '.ansi' do
    it 'returns the ansi color code string' do
      expect(described_class.ansi('31')).to eq("\e[31m")
    end
  end

  describe '.reset_color' do
    it 'returns the ansi reset code string' do
      expect(described_class.reset_color).to eq("\e[0m")
    end
  end

  describe '.wrap_in_color' do
    it 'returns a message that is colorized' do
      stub_tty(true)

      msg = 'An error occurred'

      expect(described_class.wrap_in_color(msg, described_class::COLOR_CODE_RED)).to eq("\e[31m#{msg}\e[0m")
    end
  end

  describe '.icon' do
    context 'when NO_COLOR=true is not defined' do
      it 'returns the icon code with trailing space' do
        icon = described_class::ICONS[:success]

        stub_no_color_env('')

        expect(described_class.icon(:success)).to eq("#{icon} ")
      end
    end

    context 'when NO_COLOR=true is defined' do
      it 'returns an empty string' do
        stub_no_color_env('true')

        expect(described_class.icon('doesntmatter')).to be_empty
      end
    end
  end

  describe '.colorize?' do
    context 'when NO_COLOR=true is not defined' do
      it 'returns true' do
        stub_no_color_env('')

        expect(described_class.colorize?).to be(true)
      end
    end

    context 'when NO_COLOR=true is defined' do
      it 'returns false' do
        stub_no_color_env('true')

        expect(described_class.colorize?).to be(false)
      end
    end
  end

  describe '.interactive?' do
    context 'when we have a TTY' do
      it 'returns true' do
        stub_tty(true)

        expect(described_class.interactive?).to be(true)
      end
    end

    context "when we don't have a TTY" do
      it 'returns false' do
        stub_tty(false)

        expect(described_class.interactive?).to be(false)
      end
    end
  end

  describe '.prompt' do
    let(:message) { 'Are you sure? [y/N]' }

    context 'when we have a TTY' do
      before do
        stub_tty(true)
      end

      it 'returns user input' do
        response = 'n'

        expect(Kernel).to receive(:print).with("#{message}: ")
        expect($stdout).to receive(:flush).and_call_original
        expect($stdin).to receive_message_chain(:gets, :to_s, :chomp).and_return(response)

        expect(described_class.prompt(message)).to eq(response)
      end
    end

    context "when we don't have a TTY" do
      before do
        stub_tty(false)
      end

      it 'raises an error' do
        expect(Kernel).to receive(:print).with("#{message}: ")
        expect($stdout).to receive(:flush).and_call_original
        expect { described_class.prompt(message) }.to raise_error(RuntimeError, 'Interactive terminal not available, aborting.')
      end
    end
  end
end
