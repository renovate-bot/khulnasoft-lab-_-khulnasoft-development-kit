# frozen_string_literal: true

module KDK
  module Command
    class MeasureWorkflow < MeasureBase
      WORKFLOW_SCRIPTS_FOLDER = 'support/measure_scripts'

      def run(workflows)
        @workflows = Array(workflows)

        super
      end

      private

      attr_reader :workflows

      def check!
        KDK::Output.abort('Please add a valid workflow(s) as an argument (e.g. repo_browser)', report_error: false) if workflow_script_paths.empty?

        super
      end

      def kdk_ok?
        kdk_running?
      end

      def use_git_branch_name?
        true
      end

      def workflow_script_paths
        @workflow_script_paths ||= workflows.each_with_object([]) do |path, all|
          file = "#{WORKFLOW_SCRIPTS_FOLDER}/#{path}.js"
          next unless File.exist?(file)

          all << file
        end.uniq
      end
      alias_method :items, :workflow_script_paths

      def docker_command
        command = super

        # Support testing a Single Page Application
        command << '--multi --spa'
        command << workflow_script_paths.join(' ')
      end
    end
  end
end
