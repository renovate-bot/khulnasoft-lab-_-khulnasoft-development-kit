# frozen_string_literal: true

module KDK
  module Diagnostic
    # See https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/merge_requests/4104
    class OldMiseHooks < Base
      TITLE = 'Old mise hooks'
      OLD_COMMAND = 'mise plugins update ruby; mise install'

      def success?
        !old_hook_configured?
      end

      def detail
        return if success?

        <<~MESSAGE
          Your lefthook-local.yml contains legacy tasks to update mise plugins.

          You can safely remove the task(s) referencing this command from lefthook-local.yml:

            #{OLD_COMMAND}
        MESSAGE
      end

      private

      def old_hook_configured?
        lefthook_contents.include?(OLD_COMMAND)
      end

      def lefthook_contents
        @lefthook_contents ||= begin
          File.read(config.kdk_root.join('lefthook-local.yml'))
        rescue Errno::ENOENT
          ""
        end
      end
    end
  end
end
