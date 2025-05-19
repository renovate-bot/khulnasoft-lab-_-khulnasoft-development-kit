# frozen_string_literal: true

module KDK
  module Execute
    # Rake adapter to execute tasks in KDK or Khulnasoft rails environment
    class Rake
      attr_reader :tasks

      # @param [Array<String>] *tasks a list of tasks to be executed
      def initialize(*tasks)
        @tasks = tasks
      end

      # Execute rake tasks in the KDK root folder and environment
      #
      # @param [Array] *args any arg that Shellout#execute accepts
      def execute_in_kdk(**args)
        @shellout = Shellout.new(rake_command, chdir: KDK.root).execute(**args)

        self
      end

      # Execute rake tasks in the `khulnasoft` rails environment
      #
      # @param [Array] *args any arg that Shellout#execute accepts
      def execute_in_khulnasoft(**args)
        if KDK::Dependencies.bundler_loaded?
          Bundler.with_unbundled_env do
            @shellout = Shellout.new(rake_command, chdir: KDK.config.khulnasoft.dir).execute(**args)
          end
        else
          @shellout = Shellout.new(rake_command, chdir: KDK.config.khulnasoft.dir).execute(**args)
        end

        self
      end

      # Return whether the execution was a success or not
      #
      # @return [Boolean] whether the execution was a success
      def success?
        @shellout&.success?
      end

      # Return the captured rake output
      #
      # @return [String] stdout content
      def output
        @shellout&.read_stdout
      end

      private

      # Return a list of commands necessary to execute `rake`
      #
      # It takes into consideration whether `mise` or `asdf` environment is required
      #
      # @return [Array<String (frozen)>] array of commands to be used by Shellout
      def rake_command
        cmd = %w[bundle exec rake] + tasks

        if KDK::Dependencies.mise_available?
          cmd = %w[mise exec --] + cmd
        elsif KDK::Dependencies.asdf_available?
          cmd = %w[asdf exec] + cmd
        end

        cmd
      end
    end
  end
end
