# frozen_string_literal: true

require 'pathname'
require 'shellwords'

module KDK
  module Command
    class Env < BaseCommand
      def run(args = [])
        if args.empty?
          print_env

          return true
        end

        exec(env, *args, chdir: KDK.pwd)
      end

      private

      def print_env
        env.each do |k, v|
          puts "export #{Shellwords.shellescape(k)}=#{Shellwords.shellescape(v)}"
        end
      end

      def env
        case get_project
        when 'gitaly'
          {
            'PGHOST' => config.postgresql.dir.to_s,
            'PGPORT' => config.postgresql.port.to_s
          }
        else
          {}
        end
      end

      def get_project
        relative_path = Pathname.new(Dir.pwd).relative_path_from(KDK.root).to_s
        relative_path.split('/').first
      end
    end
  end
end
