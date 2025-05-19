# frozen_string_literal: true

RSpec.describe KDK::Command::Stop do
  let(:hooks) { %w[date] }

  before do
    allow_any_instance_of(KDK::Config).to receive_message_chain('kdk.stop_hooks').and_return(hooks)
  end

  context 'with no extra arguments' do
    it 'executes hooks and stops all enabled services' do
      expect(KDK::Hooks).to receive(:with_hooks).with(hooks, 'kdk stop').and_yield
      expect(Runit).to receive(:stop).and_return(true)

      subject.run
    end
  end

  context 'with extra arguments' do
    it 'executes hooks and stops specified services' do
      services = %w[rails-web]

      expect(KDK::Hooks).to receive(:with_hooks).with(hooks, 'kdk stop').and_yield
      expect_runit_to_execute(command: 'force-stop', args: services)

      subject.run(services)
    end
  end

  def expect_runit_to_execute(command:, args: [])
    expect(Runit).to receive(:sv).with(command, args).and_return(true)
  end
end
