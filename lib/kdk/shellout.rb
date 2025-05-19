# frozen_string_literal: true

require 'open3'
require 'io/wait'
require 'benchmark'

module KDK
  # Controls execution of commands delegated to the running shell
  class Shellout
    attr_reader :args, :env, :opts, :stderr_str

    DEFAULT_EXECUTE_DISPLAY_OUTPUT = true
    DEFAULT_EXECUTE_RETRY_ATTEMPTS = 0
    DEFAULT_EXECUTE_RETRY_DELAY_SECS = 2
    BLOCK_SIZE = 1024

    ShelloutBaseError = Class.new(StandardError)
    ExecuteCommandFailedError = Class.new(ShelloutBaseError)
    StreamCommandFailedError = Class.new(ShelloutBaseError)

    def initialize(*args, **opts)
      @args = args.flatten
      @env = opts.delete(:env) || {}
      @opts = opts
    end

    def command
      @command ||= args.join(' ')
    end

    def execute(display_output: true, display_error: true, retry_attempts: DEFAULT_EXECUTE_RETRY_ATTEMPTS, retry_delay_secs: DEFAULT_EXECUTE_RETRY_DELAY_SECS)
      retried ||= false
      KDK::Output.debug("command=[#{command}], opts=[#{opts}], display_output=[#{display_output}], retry_attempts=[#{retry_attempts}]")

      duration = Benchmark.realtime do
        display_output ? stream : try_run
      end

      KDK::Output.debug("result: success?=[#{success?}], stdout=[#{read_stdout}], stderr=[#{read_stderr}], duration=[#{duration.round(2)} seconds]")

      raise ExecuteCommandFailedError, command unless success?

      if retried
        retry_success_message = "'#{command}' succeeded after retry."
        KDK::Output.success(retry_success_message)
      end

      self
    rescue StreamCommandFailedError, ExecuteCommandFailedError => e
      error_message = "'#{command}' failed."

      if (retry_attempts -= 1).negative?
        KDK::Output.error(error_message, e) if display_error

        self
      else
        retried = true
        error_message += " Retrying in #{retry_delay_secs} secs.."
        KDK::Output.error(error_message, e) if display_error

        sleep(retry_delay_secs)
        retry
      end
    end

    # Executes the command while printing the output from both stdout and stderr
    #
    # This command will stream each individual character from a separate thread
    # making it possible to visualize interactive progress bar.
    def stream(extra_options = {})
      @stdout_str = ''
      @stderr_str = ''

      # Inspiration: https://nickcharlton.net/posts/ruby-subprocesses-with-stdout-stderr-streams.html
      Open3.popen3(env, *args, opts.merge(extra_options)) do |_stdin, stdout, stderr, thread|
        @status = print_output_from_thread(thread, stdout, stderr)
      end

      read_stdout
    rescue Errno::ENOENT => e
      print_err(e.message)
      raise StreamCommandFailedError, e
    end

    def readlines(limit = -1, &block)
      @stdout_str = ''
      @stderr_str = ''
      lines = []

      Open3.popen2(env, *args, opts) do |_stdin, stdout, thread|
        stdout.each_line do |line|
          if limit == -1 || lines.count < limit
            lines << line.chomp
            yield line if block
          end
        end

        thread.join
        @status = thread.value
      end

      @stdout_str = lines.join("\n")

      lines
    end

    def run
      capture
      read_stdout
    end

    def try_run
      capture(err: '/dev/null')
      read_stdout
    rescue Errno::ENOENT
      ''
    end

    def read_stdout
      clean_string(@stdout_str.to_s.chomp)
    end

    def read_stderr
      clean_string(@stderr_str.to_s.chomp)
    end

    # Return whether last run command was successful (exit 0)
    #
    # @return [Boolean] whether last run command was successful
    def success?
      return false unless @status

      @status.success?
    end

    # Exit code from last run command
    #
    # @return [Integer] exit code
    def exit_code
      return nil unless @status

      @status.exitstatus
    end

    private

    def print_output_from_thread(thread, stdout, stderr)
      threads = Array(thread)
      threads << thread_read(stdout, method(:print_out))
      threads << thread_read(stderr, method(:print_err))
      threads.each(&:join)
      thread.value
    end

    def clean_string(str)
      str.sub("\r\e", '').chomp
    end

    def capture(extra_options = {})
      @stdout_str, @stderr_str, @status = Open3.capture3(env, *args, opts.merge(extra_options))
    end

    def thread_read(io, meth)
      logger = Support::Rake::TaskLogger.current
      Thread.new do
        Support::Rake::TaskLogger.set_current!(logger)
        until io.eof?
          ready = io.wait_readable
          next unless ready

          input = KDK::Output.ensure_utf8(io.read_nonblock(BLOCK_SIZE))
          meth.call(input)
          logger&.record_input(input) if input
        end
      end
    end

    def print_out(msg)
      @stdout_str += msg
      KDK::Output.print(msg)
    end

    def print_err(msg)
      @stderr_str += msg
      KDK::Output.print(msg, stderr: true)
    end
  end
end
