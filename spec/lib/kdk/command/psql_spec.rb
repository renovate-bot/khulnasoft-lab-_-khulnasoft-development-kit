# frozen_string_literal: true

RSpec.describe KDK::Command::Psql do
  before do
    stub_pg_bindir
  end

  context 'with no extra arguments' do
    it 'uses the development database by default' do
      expect_exec %w[psql],
        ['/usr/local/bin/psql',
          "--host=#{KDK.config.postgresql.host}",
          "--port=#{KDK.config.postgresql.port}",
          '--dbname=khulnasofthq_development',
          { chdir: KDK.root }]
    end
  end

  context 'with extra arguments' do
    it 'pass extra arguments to the psql cli application' do
      expect_exec ['psql', '-w', '-d', 'khulnasofthq_test', '-c', 'select 1'],
        ['/usr/local/bin/psql',
          "--host=#{KDK.config.postgresql.host}",
          "--port=#{KDK.config.postgresql.port}",
          '--dbname=khulnasofthq_development',
          '-w',
          '-d', 'khulnasofthq_test',
          '-c', 'select 1',
          { chdir: KDK.root }]
    end
  end

  def expect_exec(input, cmdline)
    expect(subject).to receive(:exec).with(*cmdline)

    input.shift

    subject.run(input)
  end
end
