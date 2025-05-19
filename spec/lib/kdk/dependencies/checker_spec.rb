# frozen_string_literal: true

RSpec.describe KDK::Dependencies::Checker do
  describe '.parse_version' do
    it 'returns the version in the string' do
      expect(described_class.parse_version('foo 1.2 bar')).to eq('1.2')
      expect(described_class.parse_version('foo 1.2.3.4.5.6 bar')).to eq('1.2.3.4.5.6')
    end

    it 'picks the first version looking number' do
      expect(described_class.parse_version("Yarn v0.1.1 2011 Author Name")).to eq('0.1.1')
      expect(described_class.parse_version('v0.1.1 2011')).to eq('0.1.1')
    end

    it 'uses the given prefix' do
      expect(described_class.parse_version('1.2.3 v4.5.6', prefix: 'v')).to eq('4.5.6')
    end

    it 'ignores suffixes' do
      expect(described_class.parse_version('1.2.3-foo+foo')).to eq('1.2.3')
    end

    it 'requires at least two numeric segments' do
      expect(described_class.parse_version('1')).to be_nil
    end
  end

  describe '#check_git_installed' do
    context 'when git is not installed' do
      it 'returns nil' do
        stub_check_binary('git', false)

        expect(subject.check_git_installed).to be false
      end
    end

    context 'when git is installed' do
      it 'returns nil' do
        stub_check_binary('git', true)

        expect(subject.check_git_installed).to be true
        expect(subject.error_messages).to be_empty
      end
    end
  end

  describe '#check_nginx_installed' do
    context 'nginx disabled' do
      it 'returns nil' do
        expect(subject.check_nginx_installed).to be_nil
        expect(subject.error_messages).to be_empty
      end
    end

    context 'nginx enabled' do
      let(:nginx_bin) { 'non-existing' }

      before do
        stub_kdk_yaml('nginx' => { 'enabled' => true, 'bin' => nginx_bin })
        stub_find_executable('nginx', '/usr/bin/nginx')
      end

      it 'errors when not found' do
        expect(subject.check_nginx_installed).to be_falsey
        expect(subject.error_messages).to include('ERROR: nginx is not installed or not available in your PATH.')
      end

      context 'nginx.bin points to existing executable' do
        let(:nginx_bin) { 'nginx' }

        it 'returns true' do
          expect(subject.check_nginx_installed).to be_truthy
          expect(subject.error_messages).to be_empty
        end
      end
    end
  end

  describe '#check_postgresql_version' do
    let(:psql_path) { KDK.config.postgresql.bin_dir.join('psql') }
    let(:pg_version) { "psql (PostgreSQL) #{KDK::Postgresql.target_version}" }

    it 'detects the correct version' do
      expect(subject).to receive(:check_binary).with(psql_path).and_return('psql')
      expect(subject).to receive(:`).with("#{psql_path} --version").and_return(pg_version)

      expect(subject.check_postgresql_version).to be_nil
      expect(subject.error_messages).to be_empty
    end
  end

  describe '#check_redis_version' do
    let(:redis_version) { "Redis server v=#{KDK::Redis.target_version} sha=00000000:0 malloc=libc bits=64 build=2d86b7859915655e" }

    it 'detects the correct version' do
      expect(subject).to receive(:check_binary).with('redis-server').and_return('redis-server')
      expect(subject).to receive(:`).with('redis-server --version').and_return(redis_version)

      expect(subject.check_redis_version).to be_nil
      expect(subject.error_messages).to be_empty
    end
  end

  def stub_check_binary(binary, result)
    allow(subject).to receive(:check_binary).with(binary).and_return(result)
  end
end
