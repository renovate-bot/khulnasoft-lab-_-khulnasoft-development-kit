# frozen_string_literal: true

module KDK
  module Diagnostic
    # This checks that a valid C++ compiler was detected when Ruby was built.
    # We've seen a few instances of macOS users hitting this with XCode 16
    # due to https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2222.
    class Ruby < Base
      TITLE = 'Ruby'
      XCODE_CLT_STALE_DIRECTORY = '/Library/Developer/CommandLineTools/usr/include/c++/v1'

      def success?
        cxx_compiler_ok? && ruby_flags_ok?
      end

      def detail
        return if success?

        return cxx_compiler_error_message unless cxx_compiler_ok?

        ruby_flags_error_message
      end

      private

      def ruby_flags_ok?
        RbConfig::CONFIG['CXX'] != 'false'
      end

      def cxx_compiler_ok?
        return true unless RUBY_PLATFORM.include?('darwin')

        !File.directory?(XCODE_CLT_STALE_DIRECTORY)
      end

      def ruby_flags_error_message
        <<~MESSAGE
          Ruby was built without a valid C++ compiler detected. Make sure this simple program
          can compile with clang++:

          ```
          #include <cstdio>

          int main() { return 0; }
          ```

          Example:

          ```
          clang++ /tmp/test.cc
          ```

          If this succeeds with no errors, reinstall Ruby.

        MESSAGE
      end

      def cxx_compiler_error_message
        <<~MESSAGE
          A legacy XCode Command Line Tools directory was detected:

          #{XCODE_CLT_STALE_DIRECTORY}

          This may cause issues with compiling C++ extensions. You may need to remove
          this directory. See https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/blob/main/doc/troubleshooting/ruby.md#cannot-compile-c-native-extensions
        MESSAGE
      end
    end
  end
end
