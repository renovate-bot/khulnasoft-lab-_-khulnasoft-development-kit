# frozen_string_literal: true

RSpec.describe KDK::Command::DebugInfo do
  include ShelloutHelper

  let(:kdk_root) { Pathname.new('/home/git/kdk') }
  let(:args) { [] }
  let(:shellout) { double(run: true) } # rubocop:todo RSpec/VerifiedDoubles

  subject { described_class.new.run(args) }

  before do
    allow(KDK).to receive(:root).and_return(kdk_root)
    allow(KDK::Output).to receive(:puts)
    allow(File).to receive(:exist?).with(KDK::Config::FILE).and_return(false)

    stub_shellout_response('uname -moprsv', 'exampleOS')
    stub_shellout_response('arch', 'example_arch')
    stub_shellout_response('ruby --version', '1.2.3')
    stub_shellout_response('git rev-parse --short HEAD', 'abcdef')

    env = {
      'LANGUAGE' => 'example-lang',
      'RUBY_CONFIGURE_OPTS' => 'example-ruby-config-opt'
    }

    stub_const('ENV', env)
  end

  describe '#run' do
    it 'displays debug information and returns true' do
      expect_output(/#{described_class::NEW_ISSUE_LINK}/o)

      expect_output('Operating system: exampleOS')
      expect_output('Architecture: example_arch')
      expect_output('Ruby version: 1.2.3')
      expect_output('KDK version: abcdef')
      expect_output('Environment:')

      expect_output("PATH=")
      expect_output("LANG=")
      expect_output("LANGUAGE=example-lang")
      expect_output("LC_ALL=")
      expect_output("LDFLAGS=")
      expect_output("CPPFLAGS=")
      expect_output("PKG_CONFIG_PATH=")
      expect_output("LIBPCREDIR=")
      expect_output("RUBY_CONFIGURE_OPTS=example-ruby-config-opt")

      expect(subject).to be(true)
    end

    context 'kdk.yml is present' do
      let(:kdk_config) { { example: :config, username: SecureRandom.uuid } }
      let(:kdk_yml) { kdk_config.to_yaml }
      let(:redacted_kdk_yml) { kdk_config.merge!({ username: "[redacted]" }).to_yaml }

      before do
        allow(File).to receive(:exist?).with(KDK::Config::FILE).and_return(true)
        allow(File).to receive(:read).with(KDK::Config::FILE).and_return(kdk_yml)
        allow(KDK.config).to receive(:dump!).with(user_only: true).and_return(kdk_config)
      end

      it 'includes kdk.yml contents in the debug output' do
        expect_output('KDK configuration:')
        expect_output(redacted_kdk_yml)

        expect(subject).to be(true)
      end
    end

    context 'an error is raised during shellout' do
      before do
        allow_kdk_shellout_command('uname -moprsv', any_args).and_raise('halt and catch fire')
      end

      it 'displays the error message and continues' do
        expect_output('Operating system: Unknown (halt and catch fire)')

        expect(subject).to be(true)
      end
    end
  end

  def stub_shellout_response(cmd, response)
    shellout = double(run: response) # rubocop:todo RSpec/VerifiedDoubles

    allow_kdk_shellout_command(cmd, any_args).and_return(shellout)
  end

  def expect_output(message)
    expect(KDK::Output).to receive(:puts).with(message)
  end
end
