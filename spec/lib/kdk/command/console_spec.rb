# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::Command::Console do
  it 'runs IRB with expected params' do
    expect_exec(*%w[irb -I lib -r kdk], { chdir: KDK.root })
  end

  def expect_exec(*cmdline, input: [])
    expect(subject).to receive(:exec).with(*cmdline)

    input.shift

    subject.run(input)
  end
end
