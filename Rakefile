# frozen_string_literal: true

$LOAD_PATH.unshift("#{__dir__}/lib")

require 'fileutils'
require 'rake/clean'
require 'kdk'
require 'git/configure'

Rake.add_rakelib "#{__dir__}/lib/tasks"

# Required to set task "name - comment"
Rake::TaskManager.record_task_metadata = true

def spinner_task(...)
  task(...).tap(&:enable_spinner!)
end

Rake::Task.prepend(Support::Rake::TaskWithSpinner)
Rake::Task.prepend(Support::Rake::TaskWithLogger)
Rake::Task.prepend(Support::Rake::TaskWithTelemetry)
