# frozen_string_literal: true

require_relative 'config'

module KDK
  # Config subclass to generate kdk.example.yml
  class ConfigExample < Config
    # Module that stubs reading from the environment
    module Stubbed
      def find_executable!(_bin)
        nil
      end

      def rand(max = 0)
        return max.first if max.is_a?(Range)

        0
      end

      def settings_klass
        ::KDK::ConfigExample::Settings
      end
    end

    # Environment stubbed KDK::ConfigSettings subclass
    class Settings < ::KDK::ConfigSettings
      prepend Stubbed
    end

    prepend Stubbed

    KDK_ROOT = Pathname.new('/home/git/kdk')

    def self.dump_as_yaml
      # Pin OS and target CPU to `linux x86_64` to avoid flaky `kdk.example.yml`.
      with_stubbed_rbconfig('host_os' => 'linux', 'target_cpu' => 'x86_64') do
        new.dump_as_yaml
      end
    end

    # Ensure that KDK::Machine returns same values on every platform.
    def self.with_stubbed_rbconfig(changes)
      # The config is not nested.
      orig_config = RbConfig::CONFIG.dup
      RbConfig::CONFIG.update(changes)

      yield
    ensure
      RbConfig::CONFIG.update(orig_config.slice(*changes.keys))
    end

    private_class_method :with_stubbed_rbconfig

    # Avoid messing up the superclass (i.e. `KDK::Config`)
    @attributes = superclass.attributes.dup

    def initialize
      # Override some settings which would otherwise be auto-detected
      yaml = {
        'username' => 'git',
        'git_repositories' => [],
        'restrict_cpu_count' => -1,
        'postgresql' => {
          'bin_dir' => '/usr/local/bin'
        }
      }

      super(yaml: yaml)
    end
  end
end
