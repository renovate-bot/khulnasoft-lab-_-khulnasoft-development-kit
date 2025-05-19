# frozen_string_literal: true

# Utility functions that are absent from Ruby standard library
module Utils
  # Search on PATH or default locations for provided binary and return its fullpath
  #
  # @param [String] binary name
  # @return [String] full path to the binary file
  def self.find_executable(binary)
    executable_file = proc { |name| next name if File.file?(name) && File.executable?(name) }

    # Retrieve PATH from ENV or use a fallback
    path = ENV['PATH']&.split(File::PATH_SEPARATOR) || %w[/usr/local/bin /usr/bin /bin]

    # check binary against each PATH
    path.each do |dir|
      file = File.expand_path(binary, dir)

      return file if executable_file.call(file)
    end

    nil
  end

  # If enabled, use the user's tooling manager (asdf or mise) to find an executable.
  #
  # Otherwise, fall back to the default `find_executable` logic.
  def self.executable_exist_via_tooling_manager?(binary)
    if KDK::Dependencies.asdf_available?
      KDK::Shellout.new(%W[asdf which #{binary}]).execute(display_output: false).success?
    elsif KDK::Dependencies.mise_available?
      KDK::Shellout.new(%W[mise which #{binary}]).execute(display_output: false).success?
    else
      executable_exist?(binary)
    end
  end

  # Check whether provided binary name exists on PATH or default locations
  #
  # @param [String] binary name
  def self.executable_exist?(name)
    !!find_executable(name)
  end
end
