# frozen_string_literal: true

module KDK
  module Command
    class Cells < BaseCommand
      def run(args = [])
        subcommand = args.shift
        case subcommand
        when 'up'
          up
        when 'start'
          start
        when 'stop'
          stop
        when 'restart'
          restart
        when 'status'
          status
        when 'update'
          update
        else
          id = subcommand.to_s.delete_prefix('cell-').to_i
          return run_in_cell(id, args) if cell_manager.cell_exist?(id)

          KDK::Output.warn('Usage: kdk cells up')
          KDK::Output.warn('       kdk cells start|stop|restart')
          KDK::Output.warn('       kdk cells status')
          KDK::Output.warn('       kdk cells update')
          KDK::Output.warn('       kdk cells cell-<ID> <command...>')
          abort
        end
      end

      private

      def up
        cell_manager.up
      end

      def update
        cell_manager.update
      end

      def start
        cell_manager.start
      end

      def restart
        cell_manager.restart
      end

      def run_in_cell(cell_id, args = [])
        cell_manager.run_in_cell(cell_id, args).success?
      end

      def stop
        cell_manager.stop
      end

      def status
        cell_manager.status
      end

      def cell_manager
        @cell_manager ||= CellManager.new
      end
    end
  end
end
