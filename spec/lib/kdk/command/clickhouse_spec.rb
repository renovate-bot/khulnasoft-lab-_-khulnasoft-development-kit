# frozen_string_literal: true

RSpec.describe KDK::Command::Clickhouse do
  context 'with clickhouse enabled' do
    before do
      stub_kdk_yaml(
        {
          'clickhouse' => {
            'enabled' => true,
            'bin' => '/usr/bin/clickhouse'
          }
        })
    end

    context 'with no extra arguments' do
      it 'executes clickhouse client with default params' do
        expect_exec(%w[clickhouse],
          %w[/usr/bin/clickhouse client --port=9001])
      end
    end

    context 'with extra arguments' do
      it 'executes clickhouse client passing extra arguments to the cli' do
        expect_exec(%w[clickhouse --database=gitlab],
          %w[/usr/bin/clickhouse client --port=9001 --database=gitlab])
      end
    end
  end

  context 'with clickhouse disabled' do
    it 'outputs an error message' do
      expect { subject.run }.to raise_error(SystemExit).and output(/ClickHouse is not enabled. Please check your kdk.yml configuration/).to_stderr
    end
  end

  def expect_exec(input, cmdline)
    exec_attrs = cmdline + [{ chdir: KDK.root }]

    expect(subject).to receive(:exec).with(*exec_attrs)

    input.shift

    subject.run(input)
  end
end
