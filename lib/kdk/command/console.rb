# frozen_string_literal: true

module KDK
  module Command
    # Run IRB console with KDK environment loaded
    class Console < BaseCommand
      def run(_ = [])
        console_args = %w[irb -I lib -r kdk]
        exec(*console_args, chdir: KDK.root)
      end
    end
  end
end
