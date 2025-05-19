# frozen_string_literal: true

RSpec.describe KDK::Command::RedisCli do
  context 'with no extra arguments' do
    it 'uses the development database by default' do
      expect_exec %w[redis-cli],
        ['redis-cli', '-s', KDK.config.redis.__socket_file.to_s, { chdir: KDK.root }]
    end
  end

  context 'with extra arguments' do
    it 'uses custom arguments if present' do
      expect_exec %w[redis-cli --verbose],
        ['redis-cli', '-s', KDK.config.redis.__socket_file.to_s, '--verbose', { chdir: KDK.root }]
    end
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    input.shift

    subject.run(input)
  end
end
