# frozen_string_literal: true

require 'yaml'
begin
  require 'tty-markdown'
rescue LoadError
end

module KDK
  class Announcement
    VALID_FILENAME_REGEX = /\A\d{4}_\w+\.yml/

    attr_reader :header, :body

    FilenameInvalidError = Class.new(StandardError)

    def self.from_file(filepath)
      yaml = YAML.safe_load(filepath.read)
      new(filepath, yaml['header'], yaml['body'])
    end

    def initialize(filepath, header, body)
      @filepath = Pathname.new(filepath)
      raise FilenameInvalidError unless filename_valid?

      @header = header
      @body = body
      read_cache_file_contents!
    end

    def cache_announcement_rendered
      read_cache_file_contents!

      cache_file_contents[announcement_unique_identifier] = true

      update_cached_file
    end

    def render?
      cache_file_contents[announcement_unique_identifier] != true
    end

    def render
      return unless render?

      display
      cache_announcement_rendered
    end

    private

    attr_reader :filepath
    attr_accessor :cache_file_contents

    def filename_valid?
      filepath.basename.to_s.match?(VALID_FILENAME_REGEX)
    end

    def config
      KDK.config
    end

    def display
      if defined?(TTY::Markdown)
        options = { width: 80, color: KDK::Output.colorize? ? :always : :never }
        KDK::Output.puts TTY::Markdown.parse("**#{header}**", **options)
        KDK::Output.puts TTY::Markdown.parse("***", **options)
        KDK::Output.puts TTY::Markdown.parse(body, **options)
        return
      end

      KDK::Output.info(header)
      KDK::Output.divider
      KDK::Output.puts(body)
    end

    def update_cached_file
      config.__cache_dir.mkpath
      cache_file.open('w') { |f| f.write(cache_file_contents.to_yaml) }
    end

    def announcement_unique_identifier
      @announcement_unique_identifier ||= filepath.basename.to_s[0..3]
    end

    def cache_file
      @cache_file ||= config.__cache_dir.join('.kdk-announcements.yml')
    end

    def read_cache_file_contents!
      @cache_file_contents = cache_file.exist? ? YAML.safe_load(cache_file.read) : {}
    end
  end
end

if defined?(TTY::Markdown)
  module KDKMarkdown
    # Always use blue color instead to account for contrast issues in highlighted code.
    # https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2301
    def convert_codespan(element, _opts)
      @pastel.blue(element.value)
    end
  end

  TTY::Markdown::Converter.prepend(KDKMarkdown)
end
