# frozen_string_literal: true

RSpec.describe KDK do
  before do
    allow(Utils).to receive(:executable_exist?).with('brew').and_return(true)
  end

  describe '.config' do
    it 'returns memoized config' do
      stub_kdk_yaml({})

      config = described_class.config
      expect(described_class.config).to eql(config)
    end
  end

  describe '.main' do
    it 'calls setup_rake and delegates ARGV to Command.run' do
      expect(described_class).to receive(:preload_team_member_info)
      expect(described_class).to receive(:setup_rake)

      args = ['args']
      stub_const('ARGV', args)

      expect(KDK::Command).to receive(:run).with(args)

      described_class.main
    end
  end

  describe '.pwd' do
    it 'returns the current working directory' do
      expect(Dir).to receive(:pwd).and_return('/foo')

      expect(described_class.pwd).to eq('/foo')
    end

    context 'while executing KDK.main' do
      it 'returns the user\'s working directory' do
        allow(described_class).to receive(:preload_team_member_info)
        allow(described_class).to receive(:setup_rake)
        allow(Dir).to receive(:chdir)

        args = ['args']
        stub_const('ARGV', args)
        allow(KDK::Command).to receive(:run).with(args) do
          expect(described_class.pwd).to eq(Dir.pwd)
        end

        described_class.main
      end
    end
  end

  describe '.setup_rake' do
    it 'initializes rake' do
      expect(Rake.application).to receive(:init)
        .with('rake', %W[--rakefile #{described_class.root}/Rakefile])

      expect(Rake.application).to receive(:load_rakefile)

      described_class.setup_rake
    end
  end

  describe '.set_mac_env_vars' do
    before do
      stub_const('RUBY_PLATFORM', platform)
      stub_env('PKG_CONFIG_PATH', nil)
      stub_env('LDFLAGS', nil)
      stub_env('CPPFLAGS', nil)
      stub_env('BUNDLE_BUILD__PG_QUERY', nil)
      stub_env('MACOSX_DEPLOYMENT_TARGET', nil)
      allow(described_class).to receive(:`).with('brew --prefix icu4c').and_return('')
      allow(described_class).to receive(:`).with('brew --prefix openssl').and_return('')
      allow(described_class).to receive(:`).with('sw_vers --productVersion').and_return('15.3.2')
    end

    context 'on non-darwin platforms' do
      let(:platform) { 'x86_64-linux' }

      it 'does not set icu4c paths' do
        described_class.set_mac_env_vars

        expect(ENV.fetch('PKG_CONFIG_PATH', nil)).to be_nil
        expect(ENV.fetch('LDFLAGS', nil)).to be_nil
        expect(ENV.fetch('CPPFLAGS', nil)).to be_nil
      end
    end

    context 'on darwin platforms' do
      let(:platform) { 'arm64-darwin' }
      let(:icu4c_prefix) { '/opt/homebrew/opt/icu4c' }
      let(:openssl_prefix) { '/opt/homebrew/opt/openssl' }

      context 'when homebrew is available' do
        before do
          allow(Utils).to receive(:executable_exist?).with('brew').and_return(true)
          allow(described_class).to receive(:`).with('brew --prefix icu4c').and_return("#{icu4c_prefix}\n")
          allow(described_class).to receive(:`).with('brew --prefix openssl').and_return("#{openssl_prefix}\n")
        end

        it 'sets successfully sets all required environment variables' do
          described_class.set_mac_env_vars

          expected_pkg_config_path = "#{openssl_prefix}/lib/pkgconfig:#{icu4c_prefix}/lib/pkgconfig"
          expect(ENV.fetch('PKG_CONFIG_PATH', nil)).to eq(expected_pkg_config_path)
          expect(ENV.fetch('LDFLAGS', nil)).to eq("-L#{icu4c_prefix}/lib")
          expect(ENV.fetch('CPPFLAGS', nil)).to eq("-I#{icu4c_prefix}/include")
          expect(ENV.fetch('BUNDLE_BUILD__PG_QUERY', nil)).to eq('--with-cflags=-DHAVE_STRCHRNUL')
          expect(ENV.fetch('MACOSX_DEPLOYMENT_TARGET', nil)).to eq('15.3.2')
        end
      end

      context 'when homebrew is not found' do
        before do
          allow(Utils).to receive(:executable_exist?).with('brew').and_return(false)
          allow(KDK::Output).to receive(:error)
          allow(described_class).to receive(:exit).and_throw(:exit)
        end

        it 'outputs an error and exits' do
          expect { described_class.set_mac_env_vars }.to throw_symbol(:exit)

          expect(KDK::Output).to have_received(:error).with('ERROR: Homebrew is required but cannot be found.')
          expect(described_class).to have_received(:exit).with(-1)
        end
      end

      context 'when icu4c is not found' do
        before do
          allow(Utils).to receive(:executable_exist?).with('brew').and_return(true)
          allow(described_class).to receive(:`).with('brew --prefix icu4c').and_return('')
          allow(described_class).to receive(:`).with('brew --prefix openssl').and_return("#{openssl_prefix}\n")
          allow(KDK::Output).to receive(:error)
          allow(described_class).to receive(:exit).and_throw(:exit)
        end

        it 'outputs an error and exits' do
          expect { described_class.set_mac_env_vars }.to throw_symbol(:exit)

          expect(KDK::Output).to have_received(:error).with('ERROR: icu4c is required but cannot be found.')
          expect(described_class).to have_received(:exit).with(-1)
        end
      end

      context 'when openssl is not found' do
        before do
          allow(Utils).to receive(:executable_exist?).with('brew').and_return(true)
          allow(described_class).to receive(:`).with('brew --prefix icu4c').and_return("#{icu4c_prefix}\n")
          allow(described_class).to receive(:`).with('brew --prefix openssl').and_return('')
          allow(KDK::Output).to receive(:error)
          allow(described_class).to receive(:exit).and_throw(:exit)
        end

        it 'outputs an error and exits' do
          expect { described_class.set_mac_env_vars }.to throw_symbol(:exit)

          expect(KDK::Output).to have_received(:error).with('ERROR: openssl is required but cannot be found.')
          expect(described_class).to have_received(:exit).with(-1)
        end
      end
    end
  end
end
