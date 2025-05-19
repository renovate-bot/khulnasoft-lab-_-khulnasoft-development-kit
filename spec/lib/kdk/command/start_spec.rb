# frozen_string_literal: true

RSpec.describe KDK::Command::Start do
  let(:hooks) { %w[date] }
  let(:default_url) { 'http://127.0.0.1:3000/users/sign_in' }

  before do
    allow_any_instance_of(KDK::Config).to receive_message_chain('kdk.start_hooks').and_return(hooks)
  end

  describe '#run' do
    context 'asking for help' do
      it 'prints help and exits' do
        expect { subject.run(%w[--help]) }.to output(/-h, --help         Display help/).to_stdout
      end
    end

    context 'with no extra arguments' do
      context 'without progress' do
        context 'when rails_web.enabled is true' do
          it "executes hooks and starts all enabled services, with 'KhulnaSoft available' message" do
            allow(KDK.config).to receive(:rails_web?).and_return(true)
            stub_kdk_start

            expect_runit_start_to_execute([])

            expect { subject.run }.to output(/KhulnaSoft available at/).to_stdout
          end
        end

        context 'when rails_web.enabled is false' do
          it "executes hooks and starts all enabled services, without 'KhulnaSoft available' message" do
            allow(KDK.config).to receive(:rails_web?).and_return(false)
            stub_kdk_start

            expect_runit_start_to_execute([])

            expect { subject.run }.not_to output(/KhulnaSoft available at/).to_stdout
          end
        end
      end

      context 'with --show-progress', :hide_output do
        it 'executes hooks, starts all enabled services and waits until up' do
          stub_kdk_start

          expect_runit_start_to_execute([])

          test_url_double = instance_double(KDK::TestURL, wait: true)
          expect(KDK::TestURL).to receive(:new).and_return(test_url_double)

          subject.run(%w[--show-progress])
        end
      end

      context 'with --open-when-ready' do
        it 'executes hooks, starts all enabled services and waits until up' do
          stub_kdk_start

          expect_runit_start_to_execute([])

          open_double = instance_double(KDK::Command::Open, run: true)
          expect(KDK::Command::Open).to receive(:new).and_return(open_double)

          expect { subject.run(%w[--open-when-ready]) }.to output(/KhulnaSoft available at/).to_stdout
        end
      end
    end

    context 'with extra arguments' do
      context 'without progress' do
        it 'executes hooks and starts specified services' do
          services = %w[rails-web]

          stub_kdk_start
          expect_runit_start_to_execute(services)

          subject.run(services)
        end
      end

      context 'with --show-progress' do
        it 'executes hooks and starts specified services and honors --show-progress', :hide_output do
          services = %w[rails-web]

          stub_kdk_start
          expect_runit_start_to_execute(services)
          expect(KDK::TestURL).to receive_message_chain(:new, :wait)

          subject.run(services + %w[--show-progress])
        end
      end
    end
  end

  def expect_runit_start_to_execute(args = [])
    expect(Runit).to receive(:start).with(args, quiet: false).and_return(true)
  end

  def stub_kdk_start
    allow(KDK::Hooks).to receive(:with_hooks).with(hooks, 'kdk start').and_yield
  end
end
