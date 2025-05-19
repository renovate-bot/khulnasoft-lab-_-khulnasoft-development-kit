# frozen_string_literal: true

namespace :git do
  desc 'Configure your Git with recommended settings'
  task :configure, :global do |_t, args|
    global = args[:global] == "true"

    Git::Configure.new(global: global).run!
  end
end
