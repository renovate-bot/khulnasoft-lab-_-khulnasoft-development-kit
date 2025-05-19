# frozen_string_literal: true

require_relative '../kdk'
require_relative '../kdk/task_helpers'
require 'rake/clean'

desc 'Dump the configured settings'
task 'dump_config' do
  puts KDK.config.dump_as_yaml
end

desc 'Regenerate all config files from scratch'
task generate_config_files: [:all]

desc 'Generate kdk.example.yml'
task 'kdk.example.yml' do |t|
  path = KDK.config.kdk_root.join('support/templates/kdk.example.yml.erb')
  KDK::Templates::ErbRenderer.new(path).render(t.name)
end

file KDK::Config::FILE do |t|
  FileUtils.touch(t.name)
end

# Define as a task instead of a file, so it's built unconditionally
desc nil
task 'kdk-config.mk' do |t|
  source = KDK.config.kdk_root.join('support/templates/makefiles/kdk-config.mk.erb')
  target = KDK.config.kdk_root.join(t.name)
  KDK::Templates::ErbRenderer.new(source).render(target)
end

tasks = KDK::TaskHelpers::ConfigTasks.build
configs = tasks.diffable_template_tasks.map(&:name)

desc 'Generate all config files'
task all: configs

CLOBBER.include(*configs)

# Generate a file task for each template we manage
tasks.template_tasks.each do |task|
  no_op = "[NO-OP] " unless task.enabled?
  desc "#{no_op}Generate #{task.name}"
  file task.name => [task.template, KDK::Config::FILE, *task.rake_dependencies] do |t, args|
    if task.enabled?
      destination = args[:destination] || t.name
      KDK::Templates::ErbRenderer.new(t.source, **task.erb_extra_args).safe_render!(destination)
      block = task.post_render
      # Execute post_render in context of Rake so `chmod` works.
      instance_exec(t, &block) if block
    end
  end
end

desc 'Generate postgresql/data/gitlab.conf'
file 'postgresql/data/gitlab.conf' => ['support/templates/postgresql/data/gitlab.conf.erb', KDK::Config::FILE] do |t|
  created = !File.exist?(t.name)
  modified = KDK::Templates::ErbRenderer.new(t.source).safe_render!(t.name)

  KDK::Command::Restart.new.run(['postgresql']) if created || modified
end

desc 'Generate postgresql-geo/data/gitlab.conf'
file 'postgresql-geo/data/gitlab.conf' => ['support/templates/postgresql-geo/data/gitlab.conf.erb', KDK::Config::FILE] do |t|
  created = !File.exist?(t.name)
  modified = KDK::Templates::ErbRenderer.new(t.source).safe_render!(t.name)

  KDK::Command::Restart.new.run(['postgresql-geo']) if created || modified
end

desc 'Show all the claimed ports'
task :claimed_ports do
  config = KDK.config.tap(&:validate!)

  printf("\n| %5s | %-20s |\n", 'Port', 'Service')
  printf("| %5s | %20s |\n", '-' * 5, '-' * 20)

  config.port_manager.claimed_ports_and_services.keys.sort.each do |p|
    printf("| %5d | %-20s |\n", p, config.port_manager.claimed_service_for_port(p))
  end
end
