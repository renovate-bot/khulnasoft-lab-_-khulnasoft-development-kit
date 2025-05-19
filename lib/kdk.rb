# frozen_string_literal: true

# KhulnaSoft Development Kit CLI parser / executor
#
# This file is loaded by the 'kdk' command in the gem. This file is NOT
# part of the khulnasoft-development-kit gem so that we can iterate faster.

$LOAD_PATH.unshift(__dir__)

require 'pathname'
require 'securerandom'
require 'zeitwerk'

require_relative 'kdk_src'

loader = Zeitwerk::Loader.new
loader.tag = File.basename(__FILE__, '.rb')
loader.inflector.inflect(
  {
    'kdk' => 'KDK',
    'http_helper' => 'HTTPHelper',
    'open_ldap' => 'OpenLDAP',
    'test_url' => 'TestURL'
  })
loader.push_dir(__dir__)
loader.setup

# KhulnaSoft Development Kit
module KDK
  StandardErrorWithMessage = Class.new(StandardError)
  HookCommandError = Class.new(StandardError)

  # requires `khulnasoft-development-kit` gem to be at least this version
  REQUIRED_GEM_VERSION = '0.2.18'
  PROGNAME = 'kdk'
  MAKE = RUBY_PLATFORM.include?('bsd') ? 'gmake' : 'make'

  # Entry point for the KDK binary.
  #
  # Do not remove because we need to support that use case where a new KDK binary
  # calls older KDK code.
  def self.main
    @pwd = Dir.pwd
    Dir.chdir(KDK.root)

    preload_team_member_info
    set_mac_env_vars
    setup_rake

    Command.run(ARGV)
  ensure
    Dir.chdir(@pwd)
    @pwd = nil
  end

  def self.pwd
    @pwd || Dir.pwd
  end

  def self.setup_rake
    require 'rake'
    Rake.application.init('rake', %W[--rakefile #{KDK.root}/Rakefile])
    Rake.application.load_rakefile
  end

  def self.config
    @config ||= KDK::Config.load_from_file
  end

  # Return the path to the KDK base path
  #
  # @return [Pathname] path to KDK base directory
  def self.root
    KDK::SRC
  end

  def self.make(*targets, env: {})
    sh = Shellout.new(MAKE, targets, env: env)
    sh.stream
    sh
  end

  def self.set_mac_env_vars
    # This is a temporary work around to facilitate issues with icu4c & strchnul errors in macOS 15.4 update
    return unless RUBY_PLATFORM.include?('darwin')

    unless Utils.executable_exist?('brew')
      KDK::Output.error "ERROR: Homebrew is required but cannot be found."
      exit(-1)
    end

    icu4c_prefix = `brew --prefix icu4c`.strip.split('@').first || ''
    openssl_prefix = `brew --prefix openssl`.strip.split('@').first || ''

    if icu4c_prefix.empty?
      KDK::Output.error "ERROR: icu4c is required but cannot be found."
      exit(-1)
    end

    if openssl_prefix.empty?
      KDK::Output.error "ERROR: openssl is required but cannot be found."
      exit(-1)
    end

    macos_version = `sw_vers --productVersion`.chomp
    is_atleast_15_3 = Gem::Version.new(macos_version) >= Gem::Version.new('15.3')

    ENV['PKG_CONFIG_PATH'] = [ENV.fetch('PKG_CONFIG_PATH', nil), "#{openssl_prefix}/lib/pkgconfig", "#{icu4c_prefix}/lib/pkgconfig"].compact.join(':')
    ENV['LDFLAGS'] = [ENV.fetch('LDFLAGS', nil), "-L#{icu4c_prefix}/lib"].compact.join(' ')
    ENV['CPPFLAGS'] = [ENV.fetch('CPPFLAGS', nil), "-I#{icu4c_prefix}/include"].compact.join(' ')
    ENV['BUNDLE_BUILD__PG_QUERY'] = [ENV.fetch('BUNDLE_BUILD__PG_QUERY', nil), "--with-cflags=-DHAVE_STRCHRNUL"].compact.join(' ') if is_atleast_15_3
    ENV['MACOSX_DEPLOYMENT_TARGET'] = macos_version
  end

  # Speeds up telemetry by memoizing team_member? async at KDK startup
  def self.preload_team_member_info
    Thread.new { KDK::Telemetry.team_member? }
  end
end
