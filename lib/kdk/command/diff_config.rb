# frozen_string_literal: true

require 'fileutils'

module KDK
  module Command
    class DiffConfig < BaseCommand
      def run(_ = [])
        Shellout.new(KDK::MAKE, 'touch-examples').run

        # We chdir because rake file tasks don't work with an absolute path
        results = Dir.chdir(KDK.root) do
          # Iterate over each file from files Array and print any output to
          # stderr that may have come from running `make <file>`.
          jobs.filter_map { |x| x.join[:results] }
        end

        results.each do |diff|
          output = diff.output.to_s.chomp
          next if output.empty?

          out.puts(diff.file)
          out.puts('-' * 80)
          out.puts(output)
          out.puts("\n")
        end

        true
      end

      private

      def jobs
        diffable_files.map do |file|
          Thread.new do
            Thread.current[:results] = ConfigDiff.new(file)
          end
        end
      end

      def diffable_files
        KDK::TaskHelpers::ConfigTasks.build.diffable_template_tasks.map(&:name)
      end

      class ConfigDiff
        attr_reader :file, :output

        def initialize(file)
          @file = file

          execute
        end

        def file_path
          @file_path ||= KDK.root.join(file)
        end

        private

        def execute
          # It's entirely possible file_path doesn't exist because it may be
          # a config file that user does not need and therefore has not been
          # generated.
          return nil unless file_path.exist?

          update_config_file

          @output = diff_with_unchanged
        ensure
          temporary_diff_file.delete if temporary_diff_file.exist?
        end

        def temporary_diff_file
          @temporary_diff_file ||= KDK.config.kdk_root.join('tmp', "diff_#{file.gsub(%r{/+}, '_')}")
        end

        def update_config_file
          Rake::Task[file].execute(destination: temporary_diff_file.to_s)
        end

        def diff_with_unchanged
          out = run('git', 'diff', '--no-index', '--no-prefix', '--unified=2', '--color', file, temporary_diff_file.to_s)
          out.split("\n").drop(4).join("\n")
        end

        def run(*commands)
          Shellout.new(commands, chdir: KDK.root).run
        end
      end
    end
  end
end
