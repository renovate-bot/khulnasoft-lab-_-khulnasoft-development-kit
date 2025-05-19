# frozen_string_literal: true

RSpec.describe KDK::Postgresql do
  include ShelloutHelper

  let(:yaml) { {} }
  let(:shellout_mock) { double('KDK::Shellout', run: nil, try_run: '', success?: true) } # rubocop:todo RSpec/VerifiedDoubles
  let(:config) { KDK::Config.new(yaml: yaml) }
  let(:pg_data_dir) { Pathname.new('/home/git/kdk/postgresql/data') }
  let(:pg_version_file) { pg_data_dir.join('PG_VERSION') }
  let(:postgresql_config) { double('KDK::Config', data_dir: pg_data_dir) } # rubocop:todo RSpec/VerifiedDoubles

  subject { described_class.new(config) }

  before do
    stub_pg_bindir
  end

  describe '.target_version' do
    it 'is 16.8 by default' do
      expect(described_class.target_version).to be_instance_of(Gem::Version)
      expect(described_class.target_version).to eq(Gem::Version.new('16.8'))
    end
  end

  describe '.target_version_major' do
    it 'is 16 by default' do
      expect(described_class.target_version_major).to eq(16)
    end
  end

  describe '#current_data_dir' do
    it 'returns the computed data dir' do
      stub_pg_data_dir

      expect(subject.current_data_dir).to eq(pg_data_dir)
    end
  end

  describe '#psql_cmd' do
    it 'calls pg_cmd' do
      expect(subject).to receive(:pg_cmd).with('--version', database: 'gitlabhq_development').and_call_original

      subject.psql_cmd('--version')
    end
  end

  describe '#ready?' do
    let(:error_msg) { nil }
    let(:success) { nil }
    let(:shellout_double) { kdk_shellout_double(read_stderr: error_msg, success?: success) }

    before do
      allow_kdk_shellout_command(%w[/usr/local/bin/psql --host=/home/git/kdk/postgresql --port=5432 --dbname=template1]).and_return(shellout_double)
      allow(shellout_double).to receive(:try_run).and_return(shellout_double)
      allow(subject).to receive(:sleep)
    end

    context 'when DB is not ready' do
      let(:error_msg) { 'an error has occurred' }
      let(:success) { false }

      it 'has defaults' do
        interval = 1
        retries = 10

        expect(KDK::Output).to receive(:error).with(error_msg)
        expect(subject).to receive(:sleep).with(interval).exactly(retries - 1).times

        expect(subject.ready?).to be_falsey
      end

      it 'accepts quiet parameter to silence output' do
        expect(KDK::Output).not_to receive(:error)

        expect(subject.ready?(quiet: true)).to be_falsey
      end

      it 'accepts custom interval parameter', :hide_output do
        interval = 0.5
        retries = 3

        expect(subject).to receive(:sleep).with(interval).exactly(retries - 1).times

        expect(subject.ready?(try_times: retries, interval: interval)).to be_falsey
      end
    end

    context 'when DB is ready' do
      let(:success) { true }

      it 'returns true' do
        expect(subject.ready?(try_times: 1)).to be_truthy
      end
    end
  end

  describe '#installed?' do
    let(:pg_version_file_exists) { nil }

    before do
      stub_pg_version_file(exists: pg_version_file_exists)
    end

    context 'when postgresql/data/PG_VERSION does not exist' do
      let(:pg_version_file_exists) { false }

      it 'returns false' do
        expect(subject.installed?).to be(false)
      end
    end

    context 'when postgresql/data/PG_VERSION exists' do
      let(:pg_version_file_exists) { true }

      it 'returns true' do
        expect(subject.installed?).to be(true)
      end
    end
  end

  describe '#use_tcp?' do
    context 'with host defined to a path' do
      let(:yaml) do
        {
          'postgresql' => {
            'host' => '/home/git/kdk/postgresql'
          }
        }
      end

      it 'returns false' do
        expect(subject).not_to be_use_tcp
      end
    end

    context 'with host defined to a hostname' do
      let(:yaml) do
        {
          'postgresql' => {
            'host' => 'localhost'
          }
        }
      end

      it 'returns true' do
        expect(subject).to be_use_tcp
      end
    end
  end

  describe '#db_exists?' do
    it 'calls psql with the correct arguments' do
      expect_kdk_shellout.with(array_including('/usr/local/bin/psql', '--dbname=blaat'), any_args).and_return(shellout_mock)

      expect(subject.db_exists?('blaat')).to be_truthy
    end
  end

  describe '#createdb' do
    it 'calls createdb' do
      expect_kdk_shellout.with(array_including('/usr/local/bin/createdb', 'blaat'), any_args).and_return(shellout_mock)

      subject.createdb('blaat')
    end
  end

  describe '#in_recovery?' do
    it 'queries pg_is_in_recovery()' do
      expect_kdk_shellout.with(array_including('/usr/local/bin/psql', '--command=SELECT pg_is_in_recovery();'), any_args).and_return(shellout_mock)

      subject.in_recovery?
    end

    it 'returns true when psql query returned true' do
      expect(shellout_mock).to receive(:try_run).and_return('t')
      expect_kdk_shellout.and_return(shellout_mock)

      expect(subject).to be_in_recovery
    end

    it 'returns false when psql query returned false' do
      expect(shellout_mock).to receive(:try_run).and_return('f')
      expect_kdk_shellout.and_return(shellout_mock)

      expect(subject).not_to be_in_recovery
    end

    it 'returns false when psql failed' do
      expect(shellout_mock).to receive(:try_run).and_return('error: could not connect to server')
      expect_kdk_shellout.and_return(shellout_mock)

      expect(subject).not_to be_in_recovery
    end
  end

  describe '#current_version' do
    it 'returns the PostgreSQL version set within postgresql/data/PG_VERSION' do
      stub_pg_version_file('12')

      expect(subject.current_version).to eq(12)
    end
  end

  describe '#upgrade_needed?' do
    context 'when current version is 16' do
      before do
        stub_pg_version_file('16')
      end

      context 'and target version is 9.6' do
        it 'returns false' do
          expect(subject.upgrade_needed?(9.6)).to be(false)
          expect(subject.upgrade_needed?('9.6')).to be(false)
        end
      end

      context 'and target version is 11' do
        it 'returns false' do
          expect(subject.upgrade_needed?(11)).to be(false)
          expect(subject.upgrade_needed?('11')).to be(false)
        end
      end

      context 'and target version is 12' do
        it 'returns false' do
          expect(subject.upgrade_needed?(12)).to be(false)
          expect(subject.upgrade_needed?('12')).to be(false)
        end
      end

      context 'and target version is 13' do
        it 'returns false' do
          expect(subject.upgrade_needed?(13)).to be(false)
          expect(subject.upgrade_needed?('13')).to be(false)
        end
      end

      context 'and target version is 14' do
        it 'returns false' do
          expect(subject.upgrade_needed?(14)).to be(false)
          expect(subject.upgrade_needed?('14')).to be(false)
        end
      end

      context 'and target version is the default' do
        it 'returns false' do
          expect(subject.upgrade_needed?).to be(false)
        end
      end

      context 'and target version is 17' do
        it 'returns true' do
          expect(subject.upgrade_needed?(17)).to be(true)
          expect(subject.upgrade_needed?('17')).to be(true)
        end
      end
    end
  end

  describe '#upgrade' do
    let(:cmd) { 'support/upgrade-postgresql' }
    let(:shellout_double) { kdk_shellout_double(success?: true) }

    before do
      allow_kdk_shellout_command(cmd).and_return(shellout_double)
      allow(shellout_double).to receive(:stream)
    end

    it 'runs the upgrade script' do
      expect(shellout_double).to receive(:stream)

      subject.upgrade
    end
  end

  def stub_pg_data_dir
    allow(config).to receive(:postgresql).and_return(postgresql_config)
    allow(pg_data_dir).to receive(:join).with('PG_VERSION').and_return(pg_version_file)
  end

  def stub_pg_version_file(version = nil, exists: true)
    stub_pg_data_dir
    allow(pg_version_file).to receive(:exist?).and_return(exists)
    allow(pg_version_file).to receive(:read).and_return(version) if version
  end
end
