# frozen_string_literal: true

module KDK
  module Command
    class Doctor < BaseCommand
      def initialize(diagnostics: KDK::Diagnostic.all, **args)
        @diagnostics = diagnostics
        @unexpected_error = false
        @should_autocorrect = false

        super(**args)
      end

      def run(args = [])
        unless installed?
          out.warn("KDK has not been installed so cannot run 'kdk doctor'. Try running `gem install khulnasoft-development-kit` again.")
          return false
        end

        @should_autocorrect = args.intersect?(['--correct', '-correct', '-C'])

        return false unless start_necessary_services

        show_results(diagnostic_results)
        return 2 if @unexpected_error

        handle_correctable_results(correctable_results)
        return 2 if @unexpected_error

        diagnostic_results.empty?
      end

      private

      attr_reader :diagnostics

      def installed?
        # TODO: Eventually, the Procfile will no longer exists so we need a better
        # way to determine this, but this will be OK for now.
        KDK.root.join('Procfile').exist?
      end

      def diagnostic_results
        @diagnostic_results ||= jobs.filter_map { |x| x.join[:results] }
      end

      def correctable_results
        @correctable_results ||= diagnostic_results.reject(&:unexpected_error).select(&:correctable?)
      end

      def jobs
        diagnostics.map do |diagnostic|
          Thread.new do
            Thread.current[:results] = perform_diagnosis_for(diagnostic)
            out.print(output_dot, stderr: true)
          end
        end
      end

      def perform_diagnosis_for(diagnostic)
        diagnostic unless diagnostic.success?
      rescue StandardError => e
        @unexpected_error = true
        diagnostic.unexpected_error = e
        diagnostic
      end

      def perform_corrections
        correctable_results.map do |diagnostic|
          perform_correction_for(diagnostic)
        end
      end

      def perform_correction_for(diagnostic)
        out.print("Performing correction for '#{diagnostic.title}' ")
        diagnostic.correct!
        out.success(out.wrap_in_color('success', Output::COLOR_CODE_GREEN))
      rescue StandardError => e
        @unexpected_error = true
        out.error(e.message, e)
      end

      def handle_correctable_results(correctable_results)
        out.puts("\n")

        if correctable_results.any?
          if @should_autocorrect
            out.divider
            perform_corrections
          else
            out.info("You may autocorrect #{correctable_results.size} #{correctable_results.size == 1 ? 'problem' : 'problems'} by running `kdk doctor --correct` or `kdk doctor -C`")
          end
        elsif @should_autocorrect
          out.warn('No problems to autocorrect.')
        end
      end

      def start_necessary_services
        postgresql = Postgresql.new
        return true if postgresql.ready?(try_times: 1, quiet: true)

        Runit.start('postgresql', quiet: true)

        postgresql.ready?(try_times: 20, interval: 0.5)
      end

      def show_results(results)
        out.puts("\n")
        return out.success('Your KDK is healthy.') unless results.any?

        out.warn('Your KDK may need attention.')
        results.each { |diagnostic| out.puts(diagnostic.message) }
      end

      def output_dot
        return out.wrap_in_color('E', Output::COLOR_CODE_RED) if Thread.current[:results]&.unexpected_error
        return out.wrap_in_color('W', Output::COLOR_CODE_YELLOW) if Thread.current[:results]

        out.wrap_in_color('.', Output::COLOR_CODE_GREEN)
      end
    end
  end
end
