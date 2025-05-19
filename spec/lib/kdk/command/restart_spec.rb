# frozen_string_literal: true

RSpec.describe KDK::Command::Restart do
  describe '#run' do
    context 'asking for help' do
      it 'prints help and exits' do
        expect { subject.run(%w[-h]) }.to output(/-h, --help         Display help/).to_stdout
      end
    end

    context 'with no extra arguments' do
      it 'calls stop then start without specifying services' do
        expect_any_instance_of(KDK::Command::Stop).to receive(:run).with([])
        expect(subject).to receive(:sleep).with(3)
        expect_any_instance_of(KDK::Command::Start).to receive(:run).with([])

        subject.run
      end
    end

    context 'with extra arguments' do
      it 'calls stop then start specifying services' do
        services = %w[rails-web]

        expect_any_instance_of(KDK::Command::Stop).to receive(:run).with(services)
        expect(subject).to receive(:sleep).with(3)
        expect_any_instance_of(KDK::Command::Start).to receive(:run).with(services)

        subject.run(services)
      end
    end

    context 'with --show-progress' do
      it 'calls stop then start specifying services' do
        services = %w[rails-web]
        args = %w[--show-progress]
        services_and_args = services + args

        expect_any_instance_of(KDK::Command::Stop).to receive(:run).with(services)
        expect(subject).to receive(:sleep).with(3)
        expect_any_instance_of(KDK::Command::Start).to receive(:run).with(services_and_args)

        subject.run(services_and_args)
      end
    end
  end
end
