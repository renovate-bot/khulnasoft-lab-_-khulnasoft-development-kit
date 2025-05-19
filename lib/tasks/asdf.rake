# frozen_string_literal: true

namespace :asdf do
  desc 'asdf: Uninstall unnecessary software'
  task :uninstall_unnecessary_software, [:prompt] do |_, args|
    Asdf::ToolVersions.new.uninstall_unnecessary_software!(prompt: args[:prompt] != 'false')
  end
end
