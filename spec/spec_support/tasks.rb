# frozen_string_literal: true

module TaskFormat
  extend ActiveSupport::Concern

  included do
    let(:task_name) { self.class.top_level_description.delete_prefix('rake ') }

    subject(:task) { Rake::Task[task_name] }

    before do
      task.reenable
    end

    def run_rake_task(task_name, *args)
      Rake::Task[task_name].reenable
      Rake.application.invoke_task("#{task_name}[#{args.join(',')}]")
    end
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(file_path: %r{/spec/tasks}) do |metadata|
    metadata[:type] = :task
  end

  config.include TaskFormat, type: :task
end
