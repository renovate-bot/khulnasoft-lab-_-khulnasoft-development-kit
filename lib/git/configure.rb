# frozen_string_literal: true

module Git
  class Configure
    def initialize(global: false)
      @global = global
    end

    def run!
      recommendations.each do |rec|
        KDK::Output.puts(rec.description)
        KDK::Output.puts("Possible input: #{rec.possible_values.join(',')} (default: #{rec.default})")

        input = $stdin.gets.chomp
        input = rec.default if input.empty?

        KDK::Output.abort("Invalid input: #{input}, possible values: #{rec.possible_values}") unless rec.valid_input_value?(input)

        set_config(rec.key, input)

        KDK::Output.puts # New line to separate each recommendation
      end
    end

    private

    def recommendations
      [
        Recommendation.new(
          'rerere.enabled',
          true,
          'While rebases, remember how previous conflicts were resolved and apply the same resolution'
        ),
        Recommendation.new(
          'help.autocorrect',
          0,
          'Let git auto correct commands after some deciseconds, e.g. git branhc <something> will be executed as if you typed git branch (0 = disabled, -1 = execute immediately, 50 = wait 5 secs)',
          [0, -1, 5]
        ),
        Recommendation.new(
          'fetch.prune',
          true,
          'Prune references in remotes/<remote_name> if these are removed on the server'
        ),
        Recommendation.new(
          'tag.sort',
          '-v:refname',
          'Reverse sort the tags by name, meaning that v1.1 is listed before v1.0',
          %w[-v:refname v:refname]
        )
      ]
    end

    def kdk_repositories
      @kdk_repositories ||= KDK.config.git_repositories
    end

    def set_config(key, value)
      if @global
        run_git(%W[config --global #{key} #{value}])
      else
        kdk_repositories.each do |repo|
          run_git(%W[config #{key} #{value}], repo_path: repo)
        end
      end
    end

    def run_git(args, repo_path: nil)
      # Passing an array to IO.popen guards against sh -c.
      # https://github.com/khulnasoft-lab/khulnasoft/blob/master/doc/development/shell_commands.md#bypass-the-shell-by-splitting-commands-into-separate-tokens
      raise 'command must be an array' unless args.is_a?(Array)

      args.unshift('git')

      if repo_path
        system(*args, chdir: repo_path)
      else
        system(*args)
      end
    end
  end

  class Recommendation
    attr_reader :key, :default, :possible_values, :description

    def initialize(key, default, desc, possible_values = [true, false])
      @key = key
      @default = default
      @description = desc
      @possible_values = possible_values

      raise 'default value is not valid for the recommendation' unless valid_input_value?(default)
    end

    def valid_input_value?(value)
      possible_values.map(&:to_s).include?(value.to_s)
    end
  end
end
