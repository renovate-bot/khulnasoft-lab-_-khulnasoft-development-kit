# frozen_string_literal: true

module KDK
  class Announcements
    attr_reader :announcements

    def initialize
      @announcements = parse_announcement_files
    end

    def cache_all
      announcements.each(&:cache_announcement_rendered)
    end

    def render_all
      announcements.each do |announcement|
        next unless announcement.render?

        KDK::Output.puts
        announcement.render
      end

      true
    end

    private

    attr_writer :announcements

    def parse_announcement_files
      Dir.glob(KDK.config.__data_dir.join('announcements/*.yml')).filter_map { |f| announcement_from_file(f) }
    end

    def announcement_from_file(filepath)
      Announcement.from_file(Pathname.new(filepath))
    rescue Announcement::FilenameInvalidError
      KDK::Output.warn("Ignoring #{f} as it's invalid.")
      nil
    end
  end
end
