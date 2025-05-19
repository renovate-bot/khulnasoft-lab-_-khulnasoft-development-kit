# frozen_string_literal: true

require 'erb'
require 'fileutils'

module Runit
  class Config
    attr_reader :kdk_root

    # @deprecated we should move this to `KDK::Service` when cleaning up Procfile based services
    TERM_SIGNAL = {
      'webpack' => 'KILL'
    }.freeze

    # User read-write, group and global read-only
    PERMISSION_READONLY = 0o644
    # User read write and execute, group and global read and execute
    PERMISSION_EXECUTION = 0o755

    TEMPLATE_PATH = 'support/templates'

    # @param [Pathname] kdk_root
    def initialize(kdk_root)
      @kdk_root = kdk_root
    end

    def log_dir
      kdk_root.join('log')
    end

    def services_dir
      kdk_root.join('services')
    end

    def sv_dir(service)
      kdk_root.join('sv', service.name)
    end

    def render(services:)
      FileUtils.mkdir_p(services_dir)
      FileUtils.mkdir_p(log_dir)

      max_service_length = services.map { |svc| svc.name.size }.max

      services.each_with_index do |service, i|
        create_runit_service(service)
        create_runit_down(service)
        create_runit_control_t(service)
        create_runit_log_service(service)
        create_runit_log_config(service, max_service_length, i)
        enable_runit_service(service)
      end

      FileUtils.rm(stale_service_links(services))
    end

    def stale_service_links(services)
      service_names = services.map(&:name)
      dir_matcher = %w[. ..]

      stale_entries = Dir.entries(services_dir).reject do |svc|
        service_names.include?(svc) || dir_matcher.include?(svc)
      end

      stale_entries.filter_map do |entry|
        path = services_dir.join(entry)
        next unless File.symlink?(path)

        path
      end
    end

    # Create runit `run` executable
    def create_runit_service(service)
      run = render_template('runit/run.sh.erb', service_instance: service)

      run_path = sv_dir(service).join('run')
      write_executable_file(run_path, run)
    end

    # Create runit `down` file so that `runsvdir` won't boot this service
    # until you request it with `kdk start`
    #
    # @param [KDK::Service::Base] service
    def create_runit_down(service)
      write_readonly_file(sv_dir(service).join('down'), '')
    end

    # Create runit `control/t` executable
    #
    # @param [KDK::Service::Base] service
    def create_runit_control_t(service)
      term_signal = TERM_SIGNAL.fetch(service.name, 'TERM')
      pid_path = sv_dir(service).join('supervise/pid')

      control_t = render_template('runit/control/t.rb.erb',
        pid_path: pid_path,
        term_signal: term_signal)

      control_t_path = sv_dir(service).join('control/t')
      write_executable_file(control_t_path, control_t)
    end

    # Create runit `log/run` executable
    #
    # @param [KDK::Service::Base] service
    def create_runit_log_service(service)
      service_log_dir = log_dir.join(service.name)
      FileUtils.mkdir_p(service_log_dir)

      log_run = render_template('runit/log/run.sh.erb', service_log_dir: service_log_dir)

      log_run_path = sv_dir(service).join('log/run')
      write_executable_file(log_run_path, log_run)
    end

    # Create runit `log/:service:/config` file
    #
    # @param [KDK::Service::Base] service
    # @param [Integer] max_service_length
    # @param [Integer] index
    def create_runit_log_config(service, max_service_length, index)
      log_prefix = KDK::Output.ansi(KDK::Output.color(index))
      log_label = format("%-#{max_service_length}s : ", service.name)
      reset_color = KDK::Output.reset_color

      log_config = render_template('runit/log/config.erb',
        log_prefix: log_prefix,
        log_label: log_label,
        reset_color: reset_color,
        service_instance: service)

      log_config_path = log_dir.join(service.name, 'config')
      write_readonly_file(log_config_path, log_config)
    end

    def enable_runit_service(service)
      # If the user removes this symlink, runit will stop managing this service.
      FileUtils.ln_sf(sv_dir(service), services_dir.join(service.name))
    rescue Errno::EEXIST
      # Ignore this error because it's possible there is a race condition
      # where multiple processes attempt to create this symlink.
    end

    # Return UNIX termination signal for given service
    #
    # @param [KDK::Service::Base] service
    # @return [String] UNIX termination signal
    def term_signal(service)
      TERM_SIGNAL.fetch(service.name, 'TERM')
    end

    # Write content to a given file with execution permission
    #
    # @param [String] path of the file
    # @param [String] content that will be written to the file
    def write_executable_file(path, content)
      write_file(path, content)

      File.chmod(PERMISSION_EXECUTION, path)
    end

    def write_readonly_file(path, content)
      write_file(path, content)

      File.chmod(PERMISSION_READONLY, path)
    end

    # Write content to a given file with specified permissions
    #
    # @param [String] path of the file
    # @param [String] content that will be written to the file
    def write_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      return if file_contains_content?(path, content)

      File.write(path, content)
    rescue Errno::ETXTBSY
      nil
    end

    def file_contains_content?(path, content)
      return false unless File.exist?(path)

      File.read(path) == content
    end

    # Render a template to string with optional injected local variables
    #
    # @param [String] template_path partial path starting from the template root folder
    # @param [Hash] locals any local variable that needs to be exposed in the template
    # @return [String] rendered content
    def render_template(template_path, **locals)
      template_fullpath = kdk_root.join(TEMPLATE_PATH).join(template_path)
      KDK::Templates::ErbRenderer.new(template_fullpath, **locals).render_to_string
    end
  end
end
