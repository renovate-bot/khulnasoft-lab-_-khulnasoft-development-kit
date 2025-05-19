# frozen_string_literal: true

RSpec.describe Runit do
  include ShelloutHelper

  let(:log_dir) { Pathname.new('/home/git/kdk/log') }

  describe 'ALL_DATA_ORIENTED_SERVICE_NAMES' do
    it 'returns all data service names only' do
      expect(described_class::ALL_DATA_ORIENTED_SERVICE_NAMES).to match_array(%w[minio openldap gitaly praefect redis redis-cluster postgresql-geo postgresql])
    end
  end

  context 'with stubbed services' do
    let(:data_service_names) { %w[praefect redis postgresql redis-cluster] }
    let(:non_data_service_names) { %w[khulnasoft-workhorse rails-background-jobs rails-web webpack] }

    before do
      stub_services
    end

    describe '.data_oriented_service_names' do
      subject(:data_oriented_service_names) { described_class.data_oriented_service_names }

      it 'returns data service names only' do
        expect(data_oriented_service_names).to match_array(data_service_names)
        expect(data_oriented_service_names).not_to include(*non_data_service_names)
      end
    end

    describe '.non_data_oriented_service_names' do
      subject(:non_data_oriented_service_names) { described_class.non_data_oriented_service_names }

      it 'returns non-data service names only' do
        expect(non_data_oriented_service_names).to match_array(non_data_service_names)
        expect(non_data_oriented_service_names).not_to include(*data_service_names)
      end
    end

    describe '.all_service_names' do
      subject(:all_service_names) { described_class.all_service_names }

      it 'returns all service names' do
        expect(all_service_names).to include(*data_service_names + non_data_service_names)
      end

      it 'excludes praefect-gitaly-* service names' do
        expect(all_service_names).not_to include('praefect-gitaly-0')
      end
    end

    describe '.start' do
      subject(:start) { described_class.start(services, **args) }

      shared_examples 'starts services' do |quiet|
        context 'with empty args array' do
          let(:services) { [] }

          it 'starts data services first and then non-data services last' do
            allow(described_class).to receive_messages(data_oriented_service_names: data_service_names, non_data_oriented_service_names: non_data_service_names)

            data_service_names.reverse_each do |service_name|
              expect(described_class).to receive(:sv).with('start', [service_name], quiet: quiet).and_return(true).ordered
            end

            expect(described_class).to receive(:sv).with('start', non_data_service_names, quiet: quiet).and_return(true).ordered

            start
          end
        end

        context 'with args array' do
          let(:services) { data_service_names }

          it 'starts the requested services' do
            expect(described_class).to receive(:sv).with('start', data_service_names, quiet: quiet)

            start
          end
        end

        context 'with a string' do
          let(:services) { 'postgresql' }

          it 'starts the requested service' do
            expect(described_class).to receive(:sv).with('start', [services], quiet: quiet)

            start
          end
        end
      end

      context 'with default operation' do
        it_behaves_like 'starts services', false do
          let(:args) { {} }
        end
      end

      context 'with quiet operation' do
        it_behaves_like 'starts services', true do
          let(:args) { { quiet: true } }
        end
      end
    end

    describe '.stop' do
      subject(:stop) { described_class.stop(**args) }

      shared_examples 'stops all services' do |quiet|
        it 'stops all services', :hide_output do
          allow(described_class).to receive_messages(data_oriented_service_names: data_service_names, non_data_oriented_service_names: non_data_service_names)
          allow(described_class).to receive(:unload_runsvdir!)

          expect(described_class).to receive(:sv).with('force-stop', non_data_service_names, quiet: quiet).and_return(true).ordered

          data_service_names.each do |service_name|
            expect(described_class).to receive(:sv).with('force-stop', [service_name], quiet: quiet).and_return(true).ordered
          end

          stop
        end
      end

      context 'with default operation' do
        it_behaves_like 'stops all services', false do
          let(:args) { {} }
        end
      end

      context 'with quiet operation' do
        it_behaves_like 'stops all services', true do
          let(:args) { { quiet: true } }
        end
      end
    end

    describe '.sv_shellout' do
      it 'returns a shellout with the sv command' do
        expect(described_class).to receive(:start_runsvdir).and_return(nil)
        expect(described_class).to receive(:ensure_services_are_supervised)

        sh = described_class.sv_shellout('status', ['redis'])
        expect(sh).to be_instance_of(KDK::Shellout)
        expect(sh.args).to eq(%w[sv -w 20 status /tmp/random-dir123/kdk/services/redis])
        expect(sh.opts).to eq({})
      end
    end

    describe '.sv' do
      shared_examples 'send sv command' do |shellarg|
        subject(:sv) { described_class.sv(command, services, **args) }

        let(:command) { 'stop' }
        let(:services) { data_service_names }
        let(:args) { {} }

        it 'sends the command to services' do
          expect(described_class).to receive(:start_runsvdir).and_return(nil)
          expect(described_class).to receive(:ensure_services_are_supervised)

          shellout_double2 = kdk_shellout_double(run: '', stream: '', success?: true)
          expect_kdk_shellout_command(shellarg).and_return(shellout_double2)

          expect(sv).to be_truthy
        end
      end

      it_behaves_like 'send sv command', %w[sv -w 20 stop /tmp/random-dir123/kdk/services/postgresql /tmp/random-dir123/kdk/services/praefect /tmp/random-dir123/kdk/services/redis]

      context 'when redis_cluster.enabled is true' do
        before do
          config = {
            'redis_cluster' => {
              'enabled' => true
            }
          }
          stub_kdk_yaml(config)
        end

        it_behaves_like 'send sv command', %w[sv -w 20 stop /tmp/random-dir123/kdk/services/postgresql /tmp/random-dir123/kdk/services/praefect /tmp/random-dir123/kdk/services/redis /tmp/random-dir123/kdk/services/redis-cluster]
      end
    end

    describe '.unload_runsvdir!' do
      subject(:unload_runsvdir!) { described_class.unload_runsvdir! }

      it 'send the HUP signal to the runsvdir PID' do
        pid = 99999999999

        allow(described_class).to receive(:runsvdir_pid).and_return(pid)

        expect(Process).to receive(:kill).with('HUP', pid)

        unload_runsvdir!
      end
    end

    describe '.tail' do
      subject(:tail) { described_class.tail(services) }

      let(:services) { %w[postgresql redis] }

      context 'when there are no logs to tail' do
        it 'returns true' do
          allow(described_class).to receive(:log_files).and_return([])

          expect(KDK::Output).to receive(:warn).with(<<~MSG)
            No matching services to tail.

            To view a list of services and shortcuts, run `kdk tail --help`.
          MSG

          expect(tail).to be_truthy
        end
      end

      context 'when there are logs to tail' do
        let(:log_files) { services.map { |service| Pathname.new(log_dir.join(service, 'current')) } }

        it 'attempts to tail service log files' do
          allow(described_class).to receive(:log_files).and_return(log_files)

          expect(described_class).to receive(:exec).with('tail', '-qF', '/home/git/kdk/log/postgresql/current', '/home/git/kdk/log/redis/current')

          tail
        end
      end
    end

    describe '.log_files' do
      subject(:log_files) { described_class.log_files(services) }

      let(:services) { %w[redis] }

      before do
        stub_const('Runit::LOG_DIR', log_dir)
      end

      context 'when there are no matching logs files' do
        it 'returns an empty array' do
          expect(log_files).to eq([])
        end
      end

      context 'when there are matching log_files' do
        let(:redis_log) { log_dir.join('redis/current') }

        before do
          allow(log_dir).to receive(:join).with(services.first, 'current').and_return(redis_log)
          allow(redis_log).to receive(:exist?).and_return(true)
        end

        it 'returns the list of log files' do
          expect(log_files).to contain_exactly(redis_log)
        end
      end

      context 'when there are matching shortcuts' do
        let(:services) { %w[rails] }
        let(:rails_web_log) { log_dir.join('rails-web/current') }

        before do
          allow(log_dir)
            .to receive(:glob).with('rails-*/current')
            .and_return(rails_web_log)
        end

        it 'returns the list of log files' do
          expect(log_files).to contain_exactly(rails_web_log)
        end
      end
    end
  end

  describe 'SERVICE_SHORTCUTS' do
    describe 'db' do
      it 'contains all service shortcuts' do
        expect(described_class::SERVICE_SHORTCUTS['db']).to eq('{redis,redis-cluster,postgresql,postgresql-geo,clickhouse}')
      end
    end

    describe 'workhorse' do
      it 'contains all service shortcuts' do
        expect(described_class::SERVICE_SHORTCUTS['workhorse']).to eq('khulnasoft-workhorse')
      end
    end
  end

  def stub_services
    stub_const('Runit::SERVICES_DIR', Pathname.new('/tmp/random-dir123/kdk/services'))
    stub_const('Runit::ALL_DATA_ORIENTED_SERVICE_NAMES', data_service_names)

    allow(described_class::SERVICES_DIR).to receive(:join).and_call_original
    allow(described_class::SERVICES_DIR).to receive(:exist?).and_return(true)

    children_doubles = (data_service_names + non_data_service_names).map do |service_name|
      pathname_double = Pathname.new(described_class::SERVICES_DIR.join(service_name))
      allow(pathname_double).to receive_messages(exist?: true, directory?: true)
      allow(described_class::SERVICES_DIR).to receive(:join).with(service_name).and_return(pathname_double)

      pathname_double
    end

    allow(Pathname).to receive(:new).and_call_original
    services_dir_double = instance_double(Pathname, children: children_doubles)
    allow(Pathname).to receive(:new).with(described_class::SERVICES_DIR).and_return(services_dir_double)
  end
end
