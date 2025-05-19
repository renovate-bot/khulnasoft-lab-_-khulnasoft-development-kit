# frozen_string_literal: true

RSpec.describe Support::Rake::TaskWithTelemetry do
  let(:rake) { Rake::Application.new }

  before do
    rake.load_rakefile
  end

  describe '#execute' do
    let(:telemetry) { false }

    before do
      allow(KDK::Telemetry).to receive_messages(
        telemetry_enabled?: telemetry,
        team_member?: true
      )
    end

    it 'does not send telemetry' do
      task = new_task

      expect(KDK::Telemetry).not_to receive(:send_telemetry)
      expect(KDK::Telemetry).not_to receive(:flush_events)

      task.invoke
    end

    context 'with telemetry enabled' do
      let(:telemetry) { true }

      it 'sends telemetry' do
        task = new_task

        expect(KDK::Telemetry).to receive(:send_telemetry).with(true, 'rake test-task', hash_including(:duration))

        task.invoke
      end

      context 'when the command fails' do
        it 'sends telemetry and propagates the error' do
          task = new_task do
            raise StandardError
          end

          expect(KDK::Telemetry).to receive(:send_telemetry).with(false, 'rake test-task', hash_including(:duration))

          expect { task.invoke }.to raise_error(StandardError)
        end
      end
    end
  end

  def new_task
    Rake::Task.new('test-task', rake).enhance { yield if block_given? }
  end
end
