# frozen_string_literal: true

require 'fileutils'
require 'gitlab-sdk'
require 'sentry-ruby'
require 'snowplow-tracker'

# rubocop:disable RSpec/ExpectInHook
RSpec.describe KDK::Telemetry, :with_telemetry do
  include ShelloutHelper

  let(:git_email) { 'cool-contributor@gmail.com' }
  let(:profile_output) { '' }

  before do
    sh = kdk_shellout_double(run: git_email)
    allow_kdk_shellout_command(%w[git config --get user.email]).and_return(sh)
    sh = kdk_shellout_double(read_stdout: profile_output)
    allow(sh).to receive(:execute).and_return(sh)
    allow_kdk_shellout_command(%w[profiles status -type enrollment]).and_return(sh)
  end

  describe '.with_telemetry' do
    let(:command) { 'test_command' }
    let(:args) { %w[arg1 arg2] }
    let(:telemetry_enabled) { true }
    let(:asdf?) { true }
    let(:mise?) { false }

    let(:client) { double('Client') } # rubocop:todo RSpec/VerifiedDoubles

    before do
      expect(described_class).to receive_messages(telemetry_enabled?: telemetry_enabled)
      expect(described_class).to receive(:with_telemetry).and_call_original

      allow(KDK).to receive_message_chain(:config, :telemetry, :username).and_return('testuser')
      allow(KDK).to receive_message_chain(:config, :telemetry, :environment).and_return('native')
      allow(KDK).to receive_message_chain(:config, :asdf, :opt_out?).and_return(!asdf?)
      allow(KDK).to receive_message_chain(:config, :mise, :enabled?).and_return(mise?)
      allow(described_class).to receive(:enabled_services).and_return(%w[mocked_service1 mocked_service2])
      allow(described_class).to receive_messages(client: client)

      stub_const('ARGV', args)
    end

    context 'when telemetry is not enabled' do
      let(:telemetry_enabled) { false }

      it 'does not track telemetry and directly yields the block' do
        expect { |b| described_class.with_telemetry(command, &b) }.to yield_control
      end
    end

    it 'tracks the finish of the command' do
      expect(client).to receive(:identify).with('testuser')
      expect(client).to receive(:track).with(a_string_starting_with('Finish'), hash_including(:duration, :environment, :platform, :architecture, :version_manager, :team_member, :enabled_services, :session_id, :cpu_count))

      described_class.with_telemetry(command) { true }
    end

    context 'when the block returns false' do
      it 'tracks the failure of the command' do
        expect(client).to receive(:identify).with('testuser')
        expect(client).to receive(:track).with(a_string_starting_with('Failed'), hash_including(:duration, :environment, :platform, :architecture, :version_manager, :team_member, :enabled_services, :session_id, :cpu_count))

        described_class.with_telemetry(command) { false }
      end
    end

    context 'when the block raises an error' do
      it 'tracks the failure of the command' do
        expect(client).to receive(:identify).with('testuser')
        expect(client).to receive(:track).with(a_string_starting_with('Failed'), hash_including(:duration, :environment, :platform, :architecture, :version_manager, :team_member, :session_id, :cpu_count))

        expect do
          described_class.with_telemetry(command) { raise 'Test error' }
        end.to raise_error('Test error')
      end
    end

    describe 'payload' do
      let(:payload) do
        payload = nil
        allow(client).to receive(:identify).with('testuser')
        allow(client).to receive(:track) do |_, received|
          payload = received
          nil
        end

        described_class.with_telemetry(command) { false }

        payload
      end

      describe 'version_manager' do
        it { expect(payload[:version_manager]).to eq('asdf') }

        context 'when opting out of asdf' do
          let(:asdf?) { false }

          it { expect(payload[:version_manager]).to eq('none') }
        end

        context 'when mise is enabled' do
          let(:asdf?) { false }
          let(:mise?) { true }

          it { expect(payload[:version_manager]).to eq('mise') }
        end
      end
    end
  end

  describe '.client' do
    let(:mocked_client) { instance_double(KhulnasoftSDK::Client) }
    let(:ci) { false }

    before do
      stub_env('CI', ci ? '1' : nil)
      described_class.instance_variable_set(:@client, nil)

      allow(KhulnasoftSDK::Client).to receive_messages(new: mocked_client)
    end

    after do
      described_class.instance_variable_set(:@client, nil)
    end

    it 'initializes the gitlab sdk client with the production configuration' do
      expect(SnowplowTracker::LOGGER).to receive(:level=).with(Logger::WARN)
      expect(KhulnasoftSDK::Client).to receive(:new).with(
        app_id: described_class::ANALYTICS_APP_ID,
        host: described_class::ANALYTICS_BASE_URL,
        buffer_size: 10
      ).and_return(mocked_client)

      described_class.client
    end

    context 'when in CI' do
      let(:ci) { true }

      it 'initializes the gitlab sdk client with the CI configuration' do
        expect(KhulnasoftSDK::Client).to receive(:new).with(
          app_id: described_class::CI_ANALYTICS_APP_ID,
          host: described_class::ANALYTICS_BASE_URL,
          buffer_size: 10
        ).and_return(mocked_client)

        described_class.client
      end
    end

    context 'when client is already initialized' do
      before do
        described_class.instance_variable_set(:@client, mocked_client)
      end

      it 'returns the existing client without reinitializing' do
        expect(KhulnasoftSDK::Client).not_to receive(:new)
        expect(described_class.client).to eq(mocked_client)
      end
    end
  end

  describe '.flush_events' do
    let(:mocked_client) { instance_double(KhulnasoftSDK::Client) }

    before do
      described_class.instance_variable_set(:@client, nil)
      allow(described_class).to receive(:client).and_return(mocked_client)
      allow(mocked_client).to receive(:flush_events)
    end

    after do
      described_class.instance_variable_set(:@client, nil)
    end

    context 'when telemetry endpoint is not reachable' do
      let(:telemetry_host) { 'example.com' }

      before do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)
        allow(described_class).to receive(:telemetry_host).and_return(telemetry_host)
      end

      it 'shows a warning message' do
        expect(KDK::Output).to receive(:warn).with("Could not flush telemetry events within #{KDK::Telemetry::FLUSH_TIMEOUT_SECONDS} seconds. Is #{telemetry_host} blocked or unreachable?")

        described_class.flush_events
      end
    end
  end

  describe '.init_sentry' do
    let(:config) { instance_double(Sentry::Configuration) }

    it 'initializes the sentry client with expected values' do
      allow(Sentry).to receive(:init).and_yield(config)
      allow(Sentry).to receive(:set_user)
      allow(KDK).to receive_message_chain(:config, :telemetry, :username).and_return('testuser')

      expect(config).to receive(:dsn=).with('https://4e771163209528e15a6a66a6e674ddc3@new-sentry.gitlab.net/38')
      expect(config).to receive(:breadcrumbs_logger=).with([:sentry_logger])
      expect(config).to receive(:traces_sample_rate=).with(1.0)
      expect(config).to receive_message_chain(:logger, :level=).with(Logger::WARN)
      expect(config).to receive(:server_name)
      expect(config).to receive(:server_name=).with(/\A\h{16}\z/)
      expect(config).to receive(:before_send=).with(kind_of(Proc))
      expect(Sentry).to receive(:set_user).with({ username: 'testuser' })

      described_class.init_sentry
    end
  end

  describe '.telemetry_enabled?' do
    [true, false].each do |value|
      context "when #{value}" do
        it "returns #{value}" do
          expect(KDK).to receive_message_chain(:config, :telemetry, :enabled).and_return(value)

          expect(described_class.telemetry_enabled?).to eq(value)
        end
      end
    end
  end

  describe '.team_member?' do
    let(:macos) { false }
    let(:linux) { false }

    subject { described_class.team_member? }

    before do
      described_class.remove_instance_variable(:@team_member) if described_class.instance_variable_defined?(:@team_member)

      allow(KDK::Machine).to receive_messages(macos?: macos, linux?: linux)
    end

    after do
      described_class.remove_instance_variable(:@team_member) if described_class.instance_variable_defined?(:@team_member)
    end

    it { is_expected.to be(false) }

    context 'when using an @gitlab.com email in Git' do
      let(:git_email) { 'tanuki@gitlab.com' }

      it { is_expected.to be(true) }
    end

    context 'when on MacOS' do
      let(:macos) { true }

      let(:profile_output) do
        <<~JAMF
          Enrolled via DEP: Yes
          MDM enrollment: Yes (User Approved)
          MDM server: #{server}
        JAMF
      end

      context 'when is enrolled in KhulnaSoft jamf' do
        let(:server) { 'https://gitlab.jamfcloud.com/mdm/ServerURL' }

        it { is_expected.to be(true) }
      end

      context 'when is enrolled somewhere else' do
        let(:server) { 'https://something.jamfcloud.com/mdm/ServerURL' }

        it { is_expected.to be(false) }
      end
    end

    context 'when on Linux' do
      let(:linux) { true }
      let(:hostname) { 'somehost' }
      let(:zoom_config) { Pathname(Dir.home).join('.config/zoomus.conf') }
      let(:zoom_content) { nil }

      before do
        allow(Etc).to receive(:uname).and_return({ nodename: hostname })
        allow(File).to receive(:exist?).with(zoom_config).and_return(zoom_content)
        allow(File).to receive(:foreach).with(zoom_config).and_return(zoom_content.to_s.lines) if zoom_content
      end

      it { is_expected.to be(false) }

      context 'with hostname standard' do
        let(:hostname) { 'foo--20250101-XYZ12' }

        it { is_expected.to be(true) }
      end

      context 'with zoom config' do
        context 'when KhulnaSoft related' do
          let(:zoom_content) do
            <<~CONFIG
              key=value
              conf.webserver.vendor.default=https://gitlab.zoom.us
              foo=bar
            CONFIG
          end

          it { is_expected.to be(true) }
        end

        context 'when KhulnaSoft unrelated' do
          let(:zoom_content) do
            <<~CONFIG
              key=value
              conf.webserver.vendor.default=https://zoom.us
              foo=bar
            CONFIG
          end

          it { is_expected.to be(false) }
        end
      end
    end
  end

  describe '.update_settings' do
    let(:generated_username) { SecureRandom.hex }

    before do
      allow(KDK.config).to receive_message_chain(:telemetry, :enabled).and_return(enabled)
    end

    context "when answer is 'y'" do
      let(:answer) { 'y' }

      before do
        allow(KDK.config).to receive_message_chain(:telemetry, :username).and_return(existing_username)
      end

      context 'and telemetry is already enabled' do
        let(:enabled) { true }

        context 'with already anonymized username' do
          let(:existing_username) { 'a' * 32 }

          it 'keeps telemetry enabled and does not change the username' do
            expect(KDK.config).not_to receive(:bury!).with('telemetry.enabled', anything)
            expect(KDK.config).not_to receive(:bury!).with('telemetry.username', anything)

            described_class.update_settings(answer)
          end
        end

        context 'with non-anonymized username' do
          let(:existing_username) { 'test_user' }

          before do
            allow(SecureRandom).to receive(:hex).and_return(generated_username)
          end

          it 'keeps telemetry enabled but anonymizes username' do
            expect(KDK.config).not_to receive(:bury!).with('telemetry.enabled', anything)
            expect(KDK.config).to receive(:bury!).with('telemetry.username', generated_username)
            expect(KDK.config).to receive(:save_yaml!)
            expect(KDK::Output).to receive(:info).with('Telemetry username has been anonymized.')

            described_class.update_settings(answer)
          end
        end
      end

      context 'when telemetry is currently disabled' do
        let(:enabled) { false }
        let(:existing_username) { 'test_user' }

        before do
          allow(SecureRandom).to receive(:hex).and_return(generated_username)
        end

        it 'enables telemetry and sets anonymized username' do
          expect(KDK.config).to receive(:bury!).with('telemetry.enabled', true)
          expect(KDK.config).to receive(:bury!).with('telemetry.username', generated_username)
          expect(KDK.config).to receive(:save_yaml!)
          expect(KDK::Output).to receive(:info).with('Telemetry username has been anonymized.')

          described_class.update_settings(answer)
        end
      end
    end

    context "when answer is 'n'" do
      let(:answer) { 'n' }

      context 'when telemetry is already disabled' do
        let(:enabled) { false }

        it 'keeps telemetry disabled and does not change the username' do
          expect(KDK.config).not_to receive(:bury!).with('telemetry.enabled', anything)
          expect(KDK.config).not_to receive(:bury!).with('telemetry.username', anything)

          described_class.update_settings(answer)
        end
      end

      context 'when telemetry is currently enabled' do
        let(:enabled) { true }

        it 'disables telemetry and does not change the username' do
          expect(KDK.config).to receive(:bury!).with('telemetry.enabled', false)
          expect(KDK.config).not_to receive(:bury!).with('telemetry.username', anything)
          expect(KDK.config).to receive(:save_yaml!)

          described_class.update_settings(answer)
        end
      end
    end
  end

  describe '.capture_exception' do
    let(:telemetry_enabled) { true }

    before do
      KDK.config.bury!('telemetry.enabled', telemetry_enabled)

      allow(described_class).to receive(:init_sentry)
      allow(described_class).to receive(:enabled_services).and_return(%w[mocked_service1 mocked_service2])
      allow(Sentry).to receive(:capture_exception)
    end

    context 'when telemetry is not enabled' do
      let(:telemetry_enabled) { false }

      it 'does not capture the exception' do
        described_class.capture_exception('Test error')

        expect(Sentry).not_to have_received(:capture_exception)
      end
    end

    context 'when given an exception' do
      let(:raised) do
        raise 'boom'
      rescue RuntimeError => e
        e.freeze
      end

      it 'captures the given exception' do
        described_class.capture_exception(raised)

        expect(Sentry).to have_received(:capture_exception) do |exception|
          expect(exception).to be_a(RuntimeError)
          expect(exception.message).to eq(raised.message)
          expect(exception.backtrace.first).not_to include(__FILE__)
        end
      end
    end

    context 'when given a string' do
      let(:message) { 'Test error message' }

      it 'captures a new exception with the given message' do
        described_class.capture_exception(message)

        expect(Sentry).to have_received(:capture_exception) do |exception|
          expect(exception).to be_a(StandardError)
          expect(exception.message).to eq(message)
          expect(exception.backtrace.first).not_to include(__FILE__)
        end
      end
    end
  end
end

RSpec.describe KDK::Telemetry::LoggerWithoutBacktrace do
  describe '.warn' do
    subject(:warn) { SnowplowTracker::LOGGER.warn(arg) }

    before do
      KDK::Telemetry.client
    end

    context 'with string' do
      let(:arg) { 'some failure' }

      it 'shows plain string' do
        expect_warning(/#{arg}\n\z/)
      end
    end

    context 'with exception' do
      let(:arg) { exception }
      let(:message) { 'some failure' }
      let(:backtrace) { [__FILE__] }

      before do
        exception.set_backtrace(backtrace)
      end

      [Errno::ECONNREFUSED, Errno::ECONNABORTED].each do |exception_klass|
        context "and #{exception_klass}" do
          let(:exception) { exception_klass.new(message) }

          it 'removes backtrace' do
            expect_warning(/#{message} \(#{exception_klass}\)\n\n\z/)
          end
        end
      end
    end

    def expect_warning(expected)
      expect { warn }.to output(expected).to_stderr_from_any_process
    end
  end
end

# rubocop:enable RSpec/ExpectInHook
