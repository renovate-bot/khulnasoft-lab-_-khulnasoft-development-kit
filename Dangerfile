# frozen_string_literal: true

require 'khulnasoft-dangerfiles'

Khulnasoft::Dangerfiles.for_project(self) do |khulnasoft_dangerfiles|
  khulnasoft_dangerfiles.config.files_to_category = {
    %r{\Adoc/.*(\.(md|png|gif|jpg))\z} => :docs,
    %r{\A(CONTRIBUTING|LICENSE|MAINTENANCE|PHILOSOPHY|PROCESS|README)(\.md)?\z} => :docs,
    %r{.*} => [nil]
  }.freeze

  khulnasoft_dangerfiles.import_plugins
  khulnasoft_dangerfiles.import_dangerfiles(except: %w[performance])
end
