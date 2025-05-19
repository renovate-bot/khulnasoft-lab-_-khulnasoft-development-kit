#!/usr/bin/env ruby
# frozen_string_literal: true

command = ARGV[0]
content = `#{command}`
dashes  = '-' * 80

lines_with_dashes = content.scan(/^#{dashes}\n(.*?)\n#{dashes}$/m).map(&:first)
duplicates = lines_with_dashes.select { |line| lines_with_dashes.count(line) > 1 }.uniq

if duplicates.empty?
  puts 'No duplicated lines found.'
else
  puts 'Duplicated lines found:'
  puts ''
  puts duplicates
end
