# frozen_string_literal: true

module KDK
  module Diagnostic
    class Environment < Base
      TITLE = 'Environment variables'

      def success?
        ENV['RUBY_CONFIGURE_OPTS'].to_s.empty?
      end

      def detail
        return if success?

        <<~MESSAGE
          RUBY_CONFIGURE_OPTS is configured in your environment:

          RUBY_CONFIGURE_OPTS=#{ENV.fetch('RUBY_CONFIGURE_OPTS')}

          This should not be necessary and could interfere with your
          ability to build Ruby.

          Check your dotfiles (such as ~/.zshrc) and remove any lines that set
          this variable.
        MESSAGE
      end
    end
  end
end
