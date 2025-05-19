# frozen_string_literal: true

module KDK
  # Provides information about the machine
  module Machine
    ARM64_VARIATIONS = %w[arm64 aarch64].freeze
    X86_64_VARIATIONS = %w[amd64 x86_64].freeze
    DF_AVAILABLE_REGEX = /\s+(\d+)\s+\d+%/

    # Is the machine running Linux?
    #
    # @return [Boolean] whether we are in a Linux machine
    def self.linux?
      platform == 'linux'
    end

    # Is the machine running MacOS?
    #
    # @return [Boolean] whether we are in a MacOS machine
    def self.macos?
      platform == 'darwin'
    end

    # Is the machine running on Windows Subsystem for Linux?
    #
    # @return [Boolean] whether we run Linux using Windows Subsystem for Linux
    def self.wsl?
      platform == 'linux' && Etc.uname[:release].include?('microsoft')
    end

    # Is the machine running a supported OS?
    #
    # @return [Boolean] whether we are running a supported OS
    def self.supported?
      platform != 'unknown'
    end

    # Is the machine running on an ARM64 processor?
    #
    # @return [Boolean] whether current architecture is using ARM64 architecture
    def self.arm64?
      ARM64_VARIATIONS.include?(RbConfig::CONFIG['target_cpu'])
    end

    # Is the machine running on an x86_64 processor?
    #
    # @return [Boolean] whether current CPU is using x86_64 architecture
    def self.x86_64?
      X86_64_VARIATIONS.include?(RbConfig::CONFIG['target_cpu'])
    end

    # The kernel type the machine is running on
    #
    # @return [String] darwin, linux, unknown
    def self.platform
      case RbConfig::CONFIG['host_os']
      when /darwin/i
        'darwin'
      when /linux/i
        'linux'
      else
        'unknown'
      end
    end

    # The CPU architecture of the machine
    #
    # @return [String] arm64, amd64, unknown
    def self.architecture
      return 'arm64' if arm64?
      return 'amd64' if x86_64?

      'unknown'
    end

    def self.package_platform
      if ENV['BUILD_ARCH']
        "#{platform}-#{ENV['BUILD_ARCH']}"
      else
        "#{platform}-#{architecture}"
      end
    end

    def self.available_disk_space
      output = KDK::Shellout.new(%W[df -Pk #{KDK.config.kdk_root}]).run

      DF_AVAILABLE_REGEX.match(output.split("\n").last)[1].to_i * 1000
    end

    # Reports the time in seconds since the machine last booted.
    #
    # Returns nil if the uptime is not available.
    def self.uptime
      if linux?
        File.read('/proc/uptime').split.first.to_i
      elsif macos?
        boottime = KDK::Shellout.new(%w[sysctl -n kern.boottime]).run.match(/sec = (\d+)/)[1].to_i
        return nil unless boottime

        (Time.now - boottime).to_i
      end
    rescue Errno::ENOENT
      nil
    end
  end
end
