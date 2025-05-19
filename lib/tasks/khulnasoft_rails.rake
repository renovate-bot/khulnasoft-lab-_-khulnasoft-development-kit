# frozen_string_literal: true

require_relative '../kdk/task_helpers'

desc 'Run KhulnaSoft migrations'
task 'khulnasoft-db-migrate' do
  puts

  raise 'Failed to start services for database schema migration.' unless KDK::Command::Start.new.run(['rails-migration-dependencies'])

  raise 'Database schema migration failed.' unless KDK::TaskHelpers::RailsMigration.new.migrate
end
