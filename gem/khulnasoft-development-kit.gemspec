# frozen_string_literal: true

$LOAD_PATH.unshift(File.expand_path('lib', __dir__))
require 'khulnasoft_development_kit'

Gem::Specification.new do |spec|
  spec.name          = 'khulnasoft-development-kit'
  spec.version       = KDK::GEM_VERSION
  spec.authors       = ['Jacob Vosmaer', 'KhulnaSoft']
  spec.email         = ['khulnasoft_rubygems@khulnasoft.com']

  spec.summary       = 'CLI for KhulnaSoft Development Kit'
  spec.description   = 'CLI for KhulnaSoft Development Kit.'
  spec.homepage      = 'https://github.com/khulnasoft-lab/khulnasoft-development-kit'
  spec.license       = 'MIT'
  spec.files         = ['lib/khulnasoft_development_kit.rb']
  spec.executables   = ['kdk']

  spec.required_ruby_version = '>= 3.2.0'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.add_dependency 'khulnasoft-sdk', '~> 0.3.1'
  spec.add_dependency 'rake', '~> 13.1'
  spec.add_dependency 'sentry-ruby', '~> 5.23'
  spec.add_dependency 'tty-markdown', '~> 0.7.2'
  spec.add_dependency 'tty-spinner', '~> 0.9.3'
  spec.add_dependency 'zeitwerk', '~> 2.6.15'
end
