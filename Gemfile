# frozen_string_literal: true

source 'https://rubygems.org'

gemspec path: 'gem/'

group :development do
  gem 'lefthook', '~> 1.10.10', require: false
  gem 'rubocop', require: false
  gem "rubocop-rake", "~> 0.7.0", require: false
  gem 'yard', '~> 0.9.37', require: false
  gem 'pry-byebug' # See doc/howto/pry.md
end

group :test do
  gem 'khulnasoft-styles', '~> 13.1.0', require: false
  gem 'irb', '~> 1.15.1', require: false
  gem 'rspec', '~> 3.13.0', require: false
  gem 'rspec_junit_formatter', '~> 0.6.0', require: false
  gem 'simplecov-cobertura', '~> 2.1.0', require: false
  gem 'webmock', '~> 3.25', require: false
end

group :development, :test, :danger do
  gem 'khulnasoft-dangerfiles', '~> 4.9.0', require: false
  gem 'resolv', '~> 0.6.0', require: false

  gem 'ruby-lsp', "~> 0.23.0", require: false
  gem 'ruby-lsp-rspec', "~> 0.1.10", require: false
end
