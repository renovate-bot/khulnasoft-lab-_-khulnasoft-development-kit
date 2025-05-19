# frozen_string_literal: true

RSpec.describe KDK::Config do
  let(:tmp_path) { Dir.mktmpdir('kdk-path', temp_path) }
  let(:kdk_basepath) { Pathname.new('/home/git/kdk/') }
  let(:nginx_enabled) { false }
  let(:group_saml_enabled) { false }
  let(:protected_config_files) { [] }
  let(:overwrite_changes) { false }
  let(:use_khulnasoft_sshd) { true }
  let(:listen_address) { '127.0.0.1' }
  let(:omniauth_config) { { 'group_saml' => { 'enabled' => group_saml_enabled } } }
  let(:yaml) do
    {
      'kdk' => { 'protected_config_files' => protected_config_files, 'overwrite_changes' => overwrite_changes },
      'nginx' => { 'enabled' => nginx_enabled },
      'hostname' => 'kdk.example.com',
      'omniauth' => omniauth_config,
      'sshd' => { 'use_khulnasoft_sshd' => use_khulnasoft_sshd, 'listen_address' => listen_address }
    }
  end

  let(:default_config) { described_class.new(yaml: {}) }

  subject(:config) { described_class.new(yaml: yaml) }

  describe 'common' do
    describe 'ca_path' do
      it 'is not set by default' do
        expect(config.common.ca_path).to be('')
      end
    end
  end

  describe '__platform' do
    it 'delegates to KDK::Machine.platform' do
      expect(KDK::Machine).to receive(:platform).and_call_original

      config.__platform
    end
  end

  describe '__brew_prefix_path' do
    before do
      allow(KDK::Machine).to receive(:platform).and_return(fake_platform)
    end

    context 'on a Linux system' do
      let(:fake_platform) { 'linux' }

      it 'returns an empty string' do
        expect(config.__brew_prefix_path.to_s).to eq('')
      end
    end

    context 'on a macOS system' do
      let(:fake_platform) { 'darwin' }

      before do
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:exist?).with(brew_path).and_return(true)
      end

      context 'with Apple Silicon' do
        let(:brew_path) { '/opt/homebrew/bin/brew' }

        it 'returns the brew prefix string' do
          expect(config.__brew_prefix_path.to_s).to eq('/opt/homebrew')
        end
      end

      context 'with Intel' do
        let(:brew_path) { '/usr/local/bin/brew' }

        it 'returns the brew prefix string' do
          expect(config.__brew_prefix_path.to_s).to eq('/usr/local')
        end
      end
    end
  end

  describe '__openssl_bin_path' do
    before do
      allow(KDK::Machine).to receive(:platform).and_return(fake_platform)
    end

    context 'on a Linux system' do
      let(:fake_platform) { 'linux' }

      it 'returns the location of the pathed openssl as a string', :hide_output do
        allow(Utils).to receive(:find_executable).and_return('/usr/bin/openssl')

        expect(config.__openssl_bin_path.to_s).to eq('/usr/bin/openssl')
      end
    end

    context 'on a macOS system' do
      let(:fake_platform) { 'darwin' }

      it 'returns the location of the openssl bin as a string' do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('/opt/homebrew/bin/brew').and_return(true)

        expect(config.__openssl_bin_path.to_s).to eq('/opt/homebrew/opt/openssl/bin/openssl')
      end
    end
  end

  describe 'restrict_cpu_count' do
    context 'when restrict_cpu_count is not set' do
      it 'defaults to the number of CPUS on the running machine' do
        allow(Etc).to receive(:nprocessors).and_return(6)

        expect(config.restrict_cpu_count).to eq(6)
      end
    end

    context 'when restrict_cpu_count is set' do
      it 'returns the value set by restrict_cpu_count' do
        yaml['restrict_cpu_count'] = 8

        expect(config.restrict_cpu_count).to eq(8)
      end
    end
  end

  describe 'env' do
    it 'merges variables' do
      yaml['env'] = { 'ACTION_CABLE_IN_APP' => 'false' }

      expect(config.env).to include({
        'RAILS_ENV' => 'development',
        'ACTION_CABLE_IN_APP' => 'false'
      })
    end
  end

  describe '__uri' do
    context 'for defaults' do
      it 'returns http://kdk.example.com:3000' do
        expect(config.__uri.to_s).to eq('http://kdk.example.com:3000')
      end
    end

    context 'when port is set to 1234' do
      it 'returns http://kdk.example.com:1234' do
        yaml['port'] = '1234'

        expect(config.__uri.to_s).to eq('http://kdk.example.com:1234')
      end
    end

    context 'when a relative_url_root is set' do
      it 'returns http://kdk.example.com:3000/gitlab' do
        yaml['relative_url_root'] = '/gitlab/'

        expect(config.__uri.to_s).to eq('http://kdk.example.com:3000/gitlab')
      end
    end

    context 'when https is enabled' do
      before do
        yaml['https'] = { 'enabled' => true }
      end

      it 'returns https://kdk.example.com:3000' do
        expect(config.__uri.to_s).to eq('https://kdk.example.com:3000')
      end

      context 'and port is set to 443' do
        it 'returns https://kdk.example.com/' do
          yaml['port'] = '443'

          expect(config.__uri.to_s).to eq('https://kdk.example.com')
        end
      end
    end
  end

  describe 'elasticsearch' do
    let(:checksum) { 'e7c22b994c59d9cf2b48e549b1e24666636045930d3da7c1acb299d1c3b7f931f94aae41edda2c2b207a36e10f8bcb8d45223e54878f5b316e7ce3b6bc019629' }

    describe '#enabled' do
      it 'defaults to false' do
        expect(config.elasticsearch.enabled).to be(false)
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'elasticsearch' => { 'enabled' => true } }
        end

        it 'returns true' do
          expect(config.elasticsearch.enabled).to be(true)
        end
      end
    end

    describe '#version' do
      it 'has a default value' do
        expect(config.elasticsearch.version).to match(/\d+.\d+.\d+/)
      end

      context 'when specified in config file' do
        let(:version) { '7.8.0' }
        let(:yaml) do
          { 'elasticsearch' => { 'version' => version } }
        end

        it 'returns the version from the config file' do
          expect(config.elasticsearch.version).to eq(version)
        end
      end
    end

    describe '#__architecture' do
      before do
        allow(KDK::Machine).to receive(:architecture).and_return(fake_arch)
      end

      context 'when __architecture is x86_64' do
        let(:fake_arch) { 'x86_64' }

        it 'returns x86_64' do
          expect(config.elasticsearch.__architecture).to eq('x86_64')
        end
      end

      context 'when __architecture is arm64' do
        let(:fake_arch) { 'arm64' }

        it 'returns aarch64' do
          expect(config.elasticsearch.__architecture).to eq('aarch64')
        end
      end

      context 'when __architecture is amd64' do
        let(:fake_arch) { 'amd64' }

        it 'returns x86_64' do
          expect(config.elasticsearch.__architecture).to eq('x86_64')
        end
      end
    end
  end

  describe 'repositories' do
    describe 'khulnasoft_ui' do
      it 'returns the gitlab-ui repository URL' do
        expect(config.repositories.khulnasoft_ui).to eq('https://github.com/khulnasoft-lab/khulnasoft-ui.git')
      end
    end
  end

  describe 'workhorse' do
    describe '#__active_host' do
      it 'returns the configured hostname' do
        expect(config.workhorse.__active_host).to eq(config.hostname)
      end
    end

    describe '#__listen_address' do
      it 'is set to ip and default port' do
        expect(config.workhorse.__listen_address).to eq('kdk.example.com:3333')
      end

      context 'when khulnasoft_http_router is disabled' do
        before do
          yaml['khulnasoft_http_router'] = { 'enabled' => false }
        end

        it 'is set to ip and port' do
          expect(config.workhorse.__listen_address).to eq('kdk.example.com:3000')
        end
      end
    end

    describe '#__command_line_listen_addr' do
      context 'when https is enabled' do
        it 'is kdk.example.com:0' do
          yaml['https'] = { 'enabled' => true }

          expect(config.workhorse.__command_line_listen_addr).to eq('kdk.example.com:0')
        end
      end

      context 'when https is not enabled' do
        it 'is the same as #__listen_address' do
          expect(config.workhorse.__command_line_listen_addr).to eq(config.workhorse.__listen_address)
        end
      end
    end
  end

  describe '#__active_port' do
    it 'returns 3333' do
      expect(config.workhorse.__active_port).to eq(3333)
    end

    context 'when neither nginx nor khulnasoft_http_router is enabled' do
      before do
        yaml['khulnasoft_http_router'] = { 'enabled' => false }
        yaml['nginx'] = { 'enabled' => false }
      end

      it 'returns 3000' do
        expect(config.workhorse.__active_port).to eq(3000)
      end
    end

    context 'when nginx is enabled' do
      let(:nginx_enabled) { true }

      it 'returns 3333' do
        expect(config.workhorse.__active_port).to eq(3333)
      end
    end
  end

  describe 'openldap' do
    %w[main alt].each do |server|
      describe "##{server}" do
        subject(:host) { config.openldap.public_send(server).host }

        let(:custom_host) { 'ldap.example.com' }

        it { expect(host).to eq('kdk.example.com') }

        describe "with custom openldap.#{server}.host" do
          before do
            yaml['openldap'] = {
              server => {
                'host' => custom_host
              }
            }
          end

          it { expect(host).to eq(custom_host) }
        end
      end
    end
  end

  describe 'sshd' do
    describe '#__log_file' do
      subject { config.sshd.__log_file }

      context 'when gitlab-sshd is disabled' do
        let(:use_khulnasoft_sshd) { false }

        it { is_expected.to eq("#{config.khulnasoft_shell.dir}/gitlab-shell.log") }
      end

      context 'when gitlab-sshd is enabled' do
        let(:use_khulnasoft_sshd) { true }

        it { is_expected.to eq('/dev/stdout') }
      end
    end

    describe '#__listen' do
      subject { config.sshd.__listen }

      context 'when listen address is IPv4' do
        let(:listen_address) { '127.0.0.1' }

        it { is_expected.to eq('127.0.0.1:2222') }
      end

      context 'when listen address is IPv6' do
        let(:listen_address) { '::1' }

        it { is_expected.to eq('[::1]:2222') }
      end

      context 'when listen address is a hostname' do
        let(:listen_address) { 'localhost' }

        it { is_expected.to eq('localhost:2222') }
      end
    end

    describe '#host_keys' do
      subject(:host_keys) { config.sshd.host_keys }

      it 'defaults to rsa and ed25519 keys' do
        expect(host_keys).to eq(['/home/git/kdk/openssh/ssh_host_rsa_key', '/home/git/kdk/openssh/ssh_host_ed25519_key'])
      end

      context 'with user configured host_key' do
        let(:yaml) do
          {
            'sshd' => {
              'host_key' => '/i/ve/got/the/key'
            }
          }
        end

        it 'includes the user defined key' do
          expect(host_keys).to eq(['/home/git/kdk/openssh/ssh_host_rsa_key', '/home/git/kdk/openssh/ssh_host_ed25519_key', '/i/ve/got/the/key'])
        end
      end

      context 'with user configured host_keys' do
        let(:yaml) do
          {
            'sshd' => {
              'host_keys' => ['/i/ve/got/the/key']
            }
          }
        end

        it 'matches the user defined keys' do
          expect(host_keys).to eq(['/i/ve/got/the/key'])
        end
      end
    end

    describe '#web_listen' do
      it 'defaults to a blank string' do
        expect(config.sshd.web_listen).to eq('')
      end

      context 'when prometheus is enabled' do
        let(:yaml) do
          {
            'prometheus' => {
              'enabled' => true
            }
          }
        end

        it 'defaults to 127.0.0.1:9122' do
          expect(config.sshd.web_listen).to eq('127.0.0.1:9122')
        end
      end
    end
  end

  describe '#dump!' do
    before do
      stub_pg_bindir
    end

    it 'successfully dumps the config' do
      expect do
        expect(config.dump!).to be_a_kind_of(Hash)
      end.not_to raise_error
    end

    it 'does not dump options intended for internal use only' do
      expect(config).to respond_to(:__uri)
      expect(config.dump!).not_to include('__uri')
    end

    it 'does not dump options based on question mark convenience methods' do
      expect(config.kdk).to respond_to(:debug?)
      expect(config.kdk.dump!).not_to include('debug?')
    end
  end

  describe '#validate!' do
    before do
      stub_raw_kdk_yaml(raw_yaml)
    end

    context 'when kdk.yml is valid' do
      let(:raw_yaml) { "---\nkdk:\n  debug: true" }

      it 'returns nil' do
        expect(described_class.new.kdk.validate!).to be_nil
      end
    end

    context 'with invalid YAML' do
      let(:raw_yaml) { "---\nkdk:\n  debug" }

      it 'raises an exception' do
        # Ruby 3.3 warns with 'an instance of String'
        # Ruby 3.4 warns with 'fetch'
        expect { described_class.load_from_file.kdk.validate! }.to raise_error(/undefined method ('|`)fetch' for ("debug":String|an instance of String)/)
      end
    end

    context 'with partially invalid YAML' do
      let(:raw_yaml) { "---\nkdk:\n  debug: fals" }

      it 'raises an exception' do
        expect { described_class.load_from_file.kdk.validate! }.to raise_error(/Value 'fals' for setting 'kdk.debug' is not a valid bool/)
      end
    end
  end

  describe '#[]' do
    before do
      stub_raw_kdk_yaml(raw_yaml)
    end

    context 'when looking up a single slug' do
      let(:raw_yaml) { "---\nrestrict_cpu_count: 4" }

      it 'returns the value' do
        expect(described_class.load_from_file['restrict_cpu_count'].to_s).to eq('4')
      end
    end

    context 'when looking up a multiple slugs' do
      let(:raw_yaml) { "---\nkdk:\n  debug: true" }

      it 'is not designed to return a value' do
        expect(described_class.load_from_file['kdk.debug'].to_s).to eq('')
      end
    end
  end

  describe '#username' do
    before do
      allow(Etc).to receive_message_chain(:getpwuid, :name) { 'iamfoo' }
    end

    it 'returns the short login name of the current process uid' do
      expect(config.username).to eq('iamfoo')
    end
  end

  describe '#praefect' do
    describe '#database' do
      let(:yaml) do
        {
          'praefect' => {
            'node_count' => 3,
            'database' => {
              'host' => 'localhost',
              'port' => 1234
            }
          }
        }
      end

      describe '#host' do
        it { expect(default_config.praefect.database.host).to eq(default_config.postgresql.dir.to_s) }

        context 'for a non-Geo setup' do
          it 'returns configured value' do
            expect(config.praefect.database.host).to eq('localhost')
          end
        end

        context 'for a Geo secondary' do
          let!(:yaml) do
            {
              'geo' => {
                'enabled' => true,
                'secondary' => true
              }
            }
          end

          it 'returns configured value' do
            expect(config.praefect.database.host).to eq('/home/git/kdk/postgresql-geo')
          end
        end
      end

      describe '#port' do
        it { expect(default_config.praefect.database.port).to eq(5432) }

        context 'for a non-Geo setup' do
          it 'returns configured value' do
            expect(config.praefect.database.port).to eq(1234)
          end
        end

        context 'for a Geo secondary' do
          let!(:yaml) do
            {
              'geo' => {
                'enabled' => true,
                'secondary' => true
              }
            }
          end

          it 'returns configured value' do
            expect(config.praefect.database.port).to eq(5431)
          end
        end
      end

      describe '#__storages' do
        it 'has defaults' do
          expect(default_config.praefect.__nodes.length).to eq(1)
          expect(default_config.praefect.__nodes[0].__storages.length).to eq(1)
          expect(default_config.praefect.__nodes[0].__storages[0].name).to eq('praefect-internal-0')
          expect(default_config.praefect.__nodes[0].__storages[0].path).to eq(Pathname.new('/home/git/kdk/repositories'))
        end

        it 'returns the configured value' do
          expect(config.praefect.__nodes.length).to eq(3)

          expect(config.praefect.__nodes[0].__storages.length).to eq(1)
          expect(config.praefect.__nodes[0].__storages[0].name).to eq('praefect-internal-0')
          expect(config.praefect.__nodes[0].__storages[0].path).to eq(Pathname.new('/home/git/kdk/repositories'))

          expect(config.praefect.__nodes[1].__storages.length).to eq(1)
          expect(config.praefect.__nodes[1].__storages[0].name).to eq('praefect-internal-1')
          expect(config.praefect.__nodes[1].__storages[0].path).to eq(Pathname.new('/home/git/kdk/repository_storages/praefect-gitaly-1/praefect-internal-1'))

          expect(config.praefect.__nodes[2].__storages.length).to eq(1)
          expect(config.praefect.__nodes[2].__storages[0].name).to eq('praefect-internal-2')
          expect(config.praefect.__nodes[2].__storages[0].path).to eq(Pathname.new('/home/git/kdk/repository_storages/praefect-gitaly-2/praefect-internal-2'))
        end
      end

      describe '#__praefect_build_bin_path' do
        it '/home/git/kdk/gitaly/_build/bin/praefect' do
          expect(config.praefect.__praefect_build_bin_path).to eq(Pathname.new('/home/git/kdk/gitaly/_build/bin/praefect'))
        end
      end
    end
  end

  describe '#postgresql' do
    let(:yaml) do
      {
        'postgresql' => {
          'host' => 'localhost',
          'port' => 1234,
          'active_version' => '11.9',
          'geo' => {
            'host' => 'geo',
            'port' => 5678
          }
        }
      }
    end

    describe '#host' do
      it { expect(default_config.postgresql.host).to eq(default_config.postgresql.dir.to_s) }

      it 'returns configured value' do
        expect(config.postgresql.host).to eq('localhost')
      end
    end

    describe '#port' do
      it { expect(default_config.postgresql.port).to eq(5432) }

      it 'returns configured value' do
        expect(config.postgresql.port).to eq(1234)
      end
    end

    describe '#active_version' do
      it { expect(default_config.postgresql.active_version).to eq('16.8') }

      it 'returns configured value' do
        expect(config.postgresql.active_version).to eq('11.9')
      end
    end

    describe '#geo' do
      describe '#host' do
        it { expect(default_config.postgresql.host).to eq(default_config.postgresql.dir.to_s) }

        it 'returns configured value' do
          expect(config.postgresql.geo.host).to eq('geo')
        end
      end

      describe '#port' do
        it { expect(default_config.postgresql.geo.port).to eq(5431) }

        it 'returns configured value' do
          expect(config.postgresql.geo.port).to eq(5678)
        end
      end
    end
  end

  describe "#cells" do
    describe "#enabled" do
      let(:yaml) do
        {
          'cells' => {
            'enabled' => true
          }
        }
      end

      it { expect(default_config.cells.enabled).to be(false) }
      it { expect(default_config.cells?).to be(false) }

      it { expect(config.cells.enabled).to be(true) }
      it { expect(config.cells?).to be(true) }
    end

    describe "#postgresql" do
      context 'with default settings' do
        it { expect(default_config.cells.postgresql_clusterwide.host).to eq(default_config.postgresql.host) }
        it { expect(default_config.cells.postgresql_clusterwide.port).to eq(default_config.postgresql.port) }
      end

      context 'with custom settings' do
        let(:yaml) do
          {
            'cells' => {
              'postgresql_clusterwide' => {
                'host' => '/tmp/another_kdk/postgres',
                'port' => 5432
              }
            }
          }
        end

        it { expect(config.cells.postgresql_clusterwide.host).to eq('/tmp/another_kdk/postgres') }
        it { expect(config.cells.postgresql_clusterwide.port).to eq(5432) }
      end
    end
  end

  describe '#clickhouse' do
    context 'with default settings' do
      it { expect(default_config.clickhouse.enabled).to be(false) }
      it { expect(default_config.clickhouse.dir).to eq(kdk_basepath.join('clickhouse')) }
      it { expect(default_config.clickhouse.data_dir).to eq(kdk_basepath.join('clickhouse/data')) }
      it { expect(default_config.clickhouse.log_dir).to eq(kdk_basepath.join('log/clickhouse')) }
      it { expect(default_config.clickhouse.log_level).to eq('trace') }
      it { expect(default_config.clickhouse.http_port).to eq(8123) }
      it { expect(default_config.clickhouse.tcp_port).to eq(9001) }
      it { expect(default_config.clickhouse.interserver_http_port).to eq(9009) }
      it { expect(default_config.clickhouse.max_memory_usage).to eq(1_000_000_000) }
      it { expect(default_config.clickhouse.max_thread_pool_size).to eq(1000) }
      it { expect(default_config.clickhouse.max_server_memory_usage).to eq(2_000_000_000) }

      it 'defaults bin to /usr/bin/clickhouse when no executable can be found' do
        stub_env('PATH', tmp_path)

        expect(default_config.clickhouse.bin).to eq(Pathname.new('/usr/bin/clickhouse'))
      end

      it 'returns bin full path based on find_executable' do
        unstub_find_executable
        stub_env('PATH', tmp_path)
        custom_bin_path = Pathname.new(create_dummy_executable('clickhouse'))

        expect(default_config.clickhouse.bin).to eq(custom_bin_path)
      end
    end

    context 'with custom settings' do
      let(:yaml) do
        {
          'clickhouse' => {
            'enabled' => true,
            'bin' => '/tmp/clickhouse/clickhouse-123',
            'dir' => '/tmp/clickhouse',
            'data_dir' => '/tmp/clickhouse/data-dir',
            'log_dir' => '/tmp/clickhouse/log-dir',
            'log_level' => 'warn',
            'http_port' => 1234,
            'tcp_port' => 5678,
            'interserver_http_port' => 15678,
            'max_memory_usage' => 10,
            'max_thread_pool_size' => 20,
            'max_server_memory_usage' => 30
          }
        }
      end

      it { expect(config.clickhouse.enabled).to be(true) }
      it { expect(config.clickhouse.bin).to eq(Pathname.new('/tmp/clickhouse/clickhouse-123')) }
      it { expect(config.clickhouse.dir).to eq(Pathname.new('/tmp/clickhouse')) }
      it { expect(config.clickhouse.data_dir).to eq(Pathname.new('/tmp/clickhouse/data-dir')) }
      it { expect(config.clickhouse.log_dir).to eq(Pathname.new('/tmp/clickhouse/log-dir')) }
      it { expect(config.clickhouse.log_level).to eq('warn') }
      it { expect(config.clickhouse.http_port).to eq(1234) }
      it { expect(config.clickhouse.tcp_port).to eq(5678) }
      it { expect(config.clickhouse.interserver_http_port).to eq(15678) }
      it { expect(config.clickhouse.max_memory_usage).to eq(10) }
      it { expect(config.clickhouse.max_thread_pool_size).to eq(20) }
      it { expect(config.clickhouse.max_server_memory_usage).to eq(30) }
    end
  end

  describe '#gitaly' do
    let(:praefect_enabled) { false }
    let(:storage_count) { 3 }
    let(:yaml) do
      {
        'gitaly' => {
          'storage_count' => storage_count
        },
        'praefect' => {
          'enabled' => praefect_enabled
        }
      }
    end

    describe '#dir' do
      it 'returns the gitaly directory' do
        expect(config.gitaly.dir).to eq(Pathname.new('/home/git/kdk/gitaly'))
      end
    end

    describe '#enabled' do
      context 'when praefect is disabled' do
        let(:storage_count) { 1 }

        it { expect(config.gitaly).to be_enabled }
      end

      context 'when praefect is enabled' do
        let(:praefect_enabled) { true }

        context 'when there is 1 storage' do
          let(:storage_count) { 1 }

          it { expect(config.gitaly).not_to be_enabled }
        end

        context 'when there is more than 1 storage' do
          it { expect(config.gitaly).to be_enabled }
        end
      end
    end

    describe '#__storages' do
      it 'has defaults' do
        expect(default_config.gitaly.__storages.length).to eq(1)
        expect(default_config.gitaly.__storages[0].name).to eq('default')
        expect(default_config.gitaly.__storages[0].path).to eq(Pathname.new('/home/git/kdk/repositories'))
      end

      it 'returns the configured value' do
        expect(config.gitaly.__storages.length).to eq(3)
        expect(config.gitaly.__storages[0].name).to eq('default')
        expect(config.gitaly.__storages[0].path).to eq(Pathname.new('/home/git/kdk/repositories'))
        expect(config.gitaly.__storages[1].name).to eq('gitaly-1')
        expect(config.gitaly.__storages[1].path).to eq(Pathname.new('/home/git/kdk/repository_storages/gitaly/gitaly-1'))
        expect(config.gitaly.__storages[2].name).to eq('gitaly-2')
        expect(config.gitaly.__storages[2].path).to eq(Pathname.new('/home/git/kdk/repository_storages/gitaly/gitaly-2'))
      end
    end

    describe 'auth_token' do
      it 'is not set by default' do
        expect(config.gitaly.auth_token).to be('')
      end
    end

    describe 'gitconfig' do
      it 'is not set by default' do
        expect(config.gitaly.gitconfig).to eq([])
      end

      context 'with custom gitconfig' do
        let(:gitconfig) do
          [
            { key: 'core.threads', value: '1' },
            { key: 'core.logAllRefUpdates', value: 'true' }
          ]
        end

        let(:yaml) do
          {
            'gitaly' => {
              'gitconfig' => gitconfig
            }
          }
        end

        it 'is set' do
          expect(config.gitaly.gitconfig).to eq(
            [
              { key: 'core.threads', value: '1' },
              { key: 'core.logAllRefUpdates', value: 'true' }
            ]
          )
        end
      end
    end

    describe '#__build_path' do
      it '/home/git/kdk/gitaly/_build' do
        expect(config.gitaly.__build_path).to eq(Pathname.new('/home/git/kdk/gitaly/_build'))
      end
    end

    describe '#__build_bin_path' do
      it '/home/git/kdk/gitaly/_build/bin' do
        expect(config.gitaly.__build_bin_path).to eq(Pathname.new('/home/git/kdk/gitaly/_build/bin'))
      end
    end

    describe '#__build_bin_backup_path' do
      it '/home/git/kdk/gitaly/_build/bin/gitaly-backup' do
        expect(config.gitaly.__build_bin_backup_path).to eq(Pathname.new('/home/git/kdk/gitaly/_build/bin/gitaly-backup'))
      end
    end

    describe '#__gitaly_build_bin_path' do
      it '/home/git/kdk/gitaly/_build/bin/gitaly' do
        expect(config.gitaly.__gitaly_build_bin_path).to eq(Pathname.new('/home/git/kdk/gitaly/_build/bin/gitaly'))
      end
    end

    describe 'transactions' do
      it 'is disabled by default' do
        expect(config.gitaly.transactions.enabled).to be(false)
      end

      context 'when enabled' do
        let(:yaml) do
          {
            'gitaly' => {
              'transactions' => {
                'enabled' => true
              }
            }
          }
        end

        it 'is set' do
          expect(config.gitaly.transactions.enabled).to be(true)
        end
      end
    end
  end

  context 'geo' do
    describe '#enabled' do
      it 'returns false be default' do
        expect(config.geo.enabled?).to be false
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'geo' => { 'enabled' => true } }
        end

        it 'returns true' do
          expect(config.geo.enabled?).to be true
        end
      end
    end

    describe '#secondary?' do
      it 'returns false be default' do
        expect(config.geo.secondary?).to be false
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'geo' => { 'secondary' => true } }
        end

        it 'returns true' do
          expect(config.geo.secondary?).to be true
        end
      end
    end

    describe '#registry_replication' do
      describe '#enabled' do
        it 'returns false be default' do
          expect(config.geo.registry_replication.enabled).to be false
        end

        context 'when enabled in config file' do
          let(:yaml) do
            {
              'geo' => { 'registry_replication' => { "enabled" => true } }
            }
          end

          it 'returns true' do
            expect(config.geo.registry_replication.enabled).to be true
          end
        end
      end

      describe '#primary_api_url' do
        it 'returns default URL' do
          expect(config.geo.registry_replication.primary_api_url).to eq('http://localhost:5100')
        end

        context 'when URL is specified' do
          let(:yaml) do
            {
              'geo' => { 'registry_replication' => { "primary_api_url" => 'http://localhost:5101' } }
            }
          end

          it 'returns URL from configuration file' do
            expect(config.geo.registry_replication.primary_api_url).to eq('http://localhost:5101')
          end
        end
      end
    end
  end

  describe '#config_file_protected?' do
    subject { config.config_file_protected?('foobar') }

    context 'with full wildcard protected_config_files' do
      let(:protected_config_files) { ['*'] }

      it 'returns true' do
        expect(config.config_file_protected?('foobar')).to be(true)
      end

      context 'but legacy overwrite_changes set to true' do
        let(:overwrite_changes) { true }

        it 'returns false' do
          expect(config.config_file_protected?('foobar')).to be(false)
        end
      end
    end
  end

  describe 'runner' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.runner.enabled).to be(false)
      end

      context 'when enabled in config file' do
        let(:yaml) do
          { 'runner' => { 'enabled' => true } }
        end

        it 'returns true' do
          expect(config.runner.enabled).to be(true)
        end
      end
    end

    describe '#concurrent' do
      it 'defaults to 1' do
        expect(config.runner.concurrent).to eq(1)
      end
    end

    describe '#install_mode' do
      it 'returns binary' do
        expect(config.runner.install_mode).to eq('binary')
      end
    end

    describe '#extra_hosts' do
      it 'returns []' do
        expect(config.runner.extra_hosts).to eq([])
      end
    end

    describe '#docker_host' do
      it 'returns the empty string' do
        expect(config.runner.docker_host).to eq('')
      end
    end

    describe '#image' do
      it 'returns gitlab/gitlab-runner:latest' do
        expect(config.runner.image).to eq('gitlab/gitlab-runner:latest')
      end
    end

    describe '#docker_pull' do
      it 'returns always' do
        expect(config.runner.docker_pull).to eq('always')
      end
    end

    describe '#pull_policy' do
      it 'returns if-not-present' do
        expect(config.runner.pull_policy).to eq('if-not-present')
      end
    end

    describe '#bin' do
      it 'returns gitlab-runner' do
        found = Utils.find_executable('gitlab-runner')
        path = found || '/usr/local/bin/gitlab-runner'
        expect(config.runner.bin).to eq(Pathname.new(path))
      end
    end

    describe 'network_mode_host' do
      it 'is disabled by default' do
        expect(config.runner.network_mode_host).to be(false)
      end
    end

    describe '__network_mode_host' do
      context 'when not set in kdk.yml' do
        it 'is disabled by default' do
          expect(config.runner.__network_mode_host).to be(false)
        end
      end

      context 'when enabled in kdk.yml' do
        before do
          yaml['runner'] = {
            'network_mode_host' => 'true'
          }

          allow(KDK::Machine).to receive(:platform).and_return(fake_platform)
        end

        context 'on a macOS system' do
          let(:fake_platform) { 'darwin' }

          it 'raise an exception' do
            expect { config.runner.__network_mode_host }.to raise_error('runner.network_mode_host is only supported on Linux')
          end
        end

        context 'on a Linux system' do
          let(:fake_platform) { 'linux' }

          it 'returns true' do
            expect(config.runner.__network_mode_host).to be(true)
          end
        end
      end
    end

    describe '__install_mode_binary' do
      context 'when runner is not enabled' do
        it 'returns false' do
          expect(config.runner.__install_mode_binary).to be(false)
        end
      end

      context 'when runner is enabled' do
        before do
          yaml['runner'] = {
            'enabled' => 'true'
          }
        end

        context 'when install_mode is unset' do
          it 'returns true' do
            expect(config.runner.__install_mode_binary).to be(true)
          end
        end

        context 'when install_mode is binary' do
          before do
            yaml['runner']['install_mode'] = 'binary'
          end

          it 'returns true' do
            expect(config.runner.__install_mode_binary).to be(true)
          end
        end

        context 'when install_mode is docker' do
          before do
            yaml['runner']['install_mode'] = 'docker'
          end

          it 'returns false' do
            expect(config.runner.__install_mode_binary).to be(false)
          end
        end

        context 'when executor is docker' do
          it 'returns docker' do
            expect(config.runner.executor).to eq('docker')
          end
        end

        context 'when executor is shell' do
          before do
            yaml['runner']['executor'] = 'shell'
          end

          it 'returns shell' do
            expect(config.runner.executor).to eq('shell')
          end
        end
      end
    end

    describe '__install_mode_docker' do
      context 'when runner is not enabled' do
        it 'returns false' do
          expect(config.runner.__install_mode_docker).to be(false)
        end
      end

      context 'when runner is enabled' do
        before do
          yaml['runner'] = {
            'enabled' => 'true'
          }
        end

        context 'when install_mode is unset' do
          it 'returns false' do
            expect(config.runner.__install_mode_docker).to be(false)
          end
        end

        context 'when install_mode is binary' do
          before do
            yaml['runner']['install_mode'] = 'binary'
          end

          it 'returns false' do
            expect(config.runner.__install_mode_docker).to be(false)
          end
        end

        context 'when install_mode is docker' do
          before do
            yaml['runner']['install_mode'] = 'docker'
          end

          it 'returns true' do
            expect(config.runner.__install_mode_docker).to be(true)
          end
        end
      end
    end

    describe '__add_host_flags' do
      before do
        yaml['runner'] = {
          'enabled' => 'true'
        }
      end

      context 'when extra_hosts is empty' do
        before do
          yaml['runner']['extra_hosts'] = []
        end

        it 'returns an empty string' do
          flags = config.runner.__add_host_flags

          expect(flags).to be_a(String)
          expect(flags).to be_empty
        end
      end

      context 'when extra_hosts contains a single item' do
        before do
          yaml['runner']['extra_hosts'] = ['kdk.test:172.16.123.1']
        end

        it 'returns a single flag' do
          expect(config.runner.__add_host_flags).to eq("--add-host='kdk.test:172.16.123.1'")
        end
      end

      context 'when extra_hosts contains multiple items' do
        before do
          yaml['runner']['extra_hosts'] = ['kdk.test:172.16.123.1', 'kdk.test:192.168.65.2', 'registry.kdk.test:172.17.0.4']
        end

        it 'returns multiple flags separated by spaces' do
          flags = config.runner.__add_host_flags

          expect(flags).to eq("--add-host='kdk.test:172.16.123.1' --add-host='kdk.test:192.168.65.2' --add-host='registry.kdk.test:172.17.0.4'")
        end
      end
    end

    describe '__ssl_certificate' do
      let(:yaml) do
        {
          'runner' => { 'enabled' => 'true' },
          'nginx' => {
            'ssl' => {
              'certificate' => '/path/to/hostname.pem',
              'key' => '/path/to/hostname.key'
            }
          }
        }
      end

      it 'converts to a relative path' do
        cert = config.runner.__ssl_certificate

        expect(cert).to be_a(String)
        expect(cert).to eq('hostname.crt')
      end

      context 'when __ssl_certificate is overriden' do
        before do
          yaml['runner']['__ssl_certificate'] = '/path/to/ssl/cert'
        end

        it 'returns an empty string' do
          cert = config.runner.__ssl_certificate

          expect(cert).to be_a(String)
          expect(cert).to eq('/path/to/ssl/cert')
        end
      end
    end

    context 'when config_file exists' do
      before do
        yaml['runner'] = {
          'config_file' => Tempfile.new
        }
      end

      describe 'enabled' do
        it 'is disabled by default' do
          expect(config.runner.enabled).to be(false)
        end
      end
    end
  end

  describe '#listen_address' do
    it 'returns 127.0.0.1 by default' do
      expect(config.listen_address).to eq('127.0.0.1')
    end
  end

  describe 'license' do
    describe 'customer_portal_url' do
      it 'returns staging customer portal URL by default' do
        expect(config.license.customer_portal_url).to eq('https://customers.staging.gitlab.com')
      end
    end

    describe 'license_mode' do
      it 'returns test by default' do
        expect(config.license.license_mode).to eq('test')
      end
    end
  end

  describe 'khulnasoft' do
    describe 'auto_update' do
      it 'is enabled by default' do
        expect(config.gitlab.auto_update).to be(true)
        expect(config.gitlab.auto_update?).to be(true)
      end
    end

    describe 'default_branch' do
      it 'is set to master by default' do
        expect(config.gitlab.default_branch).to be('master')
      end
    end

    describe 'lefthook_enabled' do
      it 'is enabled by default' do
        expect(config.gitlab.lefthook_enabled?).to be(true)
      end
    end

    describe '#dir' do
      it 'returns the KhulnaSoft directory' do
        expect(config.gitlab.dir).to eq(Pathname.new('/home/git/kdk/gitlab'))
      end
    end

    describe '#log_dir' do
      it 'returns the KhulnaSoft log directory' do
        expect(config.gitlab.log_dir).to eq(Pathname.new('/home/git/kdk/gitlab/log'))
      end
    end

    describe '#cache_classes' do
      it 'returns if Ruby classes should be cached' do
        expect(config.gitlab.cache_classes).to be(false)
      end
    end

    describe '#gitaly_disable_request_limits' do
      it 'returns if Gitaly request limit checks should be disabled' do
        expect(config.gitlab.gitaly_disable_request_limits).to be(false)
      end
    end

    describe 'rails' do
      describe '#hostname' do
        it 'returns kdk.example.com by default' do
          expect(config.gitlab.rails.hostname).to eq('kdk.example.com')
        end
      end

      describe '#port' do
        it 'returns 3000 by default' do
          expect(config.gitlab.rails.port).to eq(3000)
        end
      end

      describe '#bootsnap' do
        it 'returns true by default' do
          expect(config.gitlab.rails.bootsnap?).to be(true)
        end
      end

      context 'https' do
        describe '#enabled' do
          it 'returns false by default' do
            expect(config.gitlab.rails.https.enabled).to be(false)
            expect(config.gitlab.rails.https.enabled?).to be(false)
            expect(config.gitlab.rails.https?).to be(false)
          end
        end
      end

      describe '#__socket_file' do
        it 'returns the KhulnaSoft socket path' do
          expect(config.gitlab.rails.__socket_file).to eq(Pathname.new('/home/git/kdk/gitlab.socket'))
        end
      end

      describe '#__socket_file_escaped' do
        it 'returns the KhulnaSoft socket path CGI escaped' do
          expect(config.gitlab.rails.__socket_file_escaped.to_s).to eq('%2Fhome%2Fgit%2Fkdk%2Fgitlab.socket')
        end
      end

      describe '#listen_settings' do
        it 'defaults to UNIX socket' do
          expect(config.gitlab.rails.address).to eq('')
          expect(config.gitlab.rails.__bind).to eq('unix:///home/git/kdk/gitlab.socket')
          expect(config.gitlab.rails.__workhorse_url).to eq('/home/git/kdk/gitlab.socket')
          expect(config.gitlab.rails.__listen_settings.__protocol).to eq('unix')
          expect(config.gitlab.rails.__listen_settings.__address).to eq('/home/git/kdk/gitlab.socket')
          expect(config.workhorse.__listen_settings.__type).to eq('authSocket')
          expect(config.workhorse.__listen_settings.__address).to eq('/home/git/kdk/gitlab.socket')
        end
      end

      context 'with TCP address' do
        before do
          yaml['khulnasoft'] = {
            'rails' => {
              'address' => 'localhost:3443'
            }
          }
        end

        it 'sets listen_settings to HTTP port' do
          expect(config.gitlab.rails.address).to eq('localhost:3443')
          expect(config.gitlab.rails.__bind).to eq('tcp://localhost:3443')
          expect(config.gitlab.rails.__workhorse_url).to eq('http://localhost:3443')
          expect(config.gitlab.rails.__listen_settings.__protocol).to eq('tcp')
          expect(config.gitlab.rails.__listen_settings.__address).to eq('localhost:3443')
          expect(config.workhorse.__listen_settings.__type).to eq('authBackend')
          expect(config.workhorse.__listen_settings.__address).to eq('http://localhost:3443')
        end
      end

      describe 'bundle_gemfile' do
        it 'is /home/git/kdk/gitlab/Gemfile by default' do
          expect(config.gitlab.rails.bundle_gemfile).to eq('/home/git/kdk/gitlab/Gemfile')
        end
      end

      describe 'multiple_databases' do
        it 'is disabled by default' do
          expect(config.gitlab.rails.multiple_databases).to be(false)
        end
      end

      describe 'databases' do
        describe 'ci' do
          describe 'enabled' do
            it 'is enabled by default' do
              expect(config.gitlab.rails.databases.ci.enabled).to be(true)
            end
          end

          describe 'use_main_database' do
            it 'is disabled by default' do
              expect(config.gitlab.rails.databases.ci.use_main_database).to be(false)
            end
          end

          describe '__enabled' do
            it 'is enabled by default' do
              expect(config.gitlab.rails.databases.ci.__enabled).to be(true)
            end

            context 'when config.gitlab.rails.multiple_databases is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'multiple_databases' => true
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.ci.__enabled).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.ci.enabled is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'ci' => {
                        'enabled' => true
                      }
                    }
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.ci.__enabled).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.ci.enabled is false' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'ci' => {
                        'enabled' => false
                      }
                    }
                  }
                }
              end

              it 'is disabled' do
                expect(config.gitlab.rails.databases.ci.__enabled).to be(false)
              end
            end
          end

          describe '__use_main_database' do
            it 'is disabled by default' do
              expect(config.gitlab.rails.databases.ci.__use_main_database).to be(false)
            end

            context 'when config.gitlab.rails.multiple_databases is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'multiple_databases' => 'true'
                  }
                }
              end

              it 'is disabled' do
                expect(config.gitlab.rails.databases.ci.__use_main_database).to be(false)
              end
            end

            context 'when config.gitlab.rails.databases.ci.enabled is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'ci' => {
                        'enabled' => true
                      }
                    }
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.ci.__enabled).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.ci.enabled is false' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'ci' => {
                        'enabled' => false
                      }
                    }
                  }
                }
              end

              it 'is disabled' do
                expect(config.gitlab.rails.databases.ci.__enabled).to be(false)
              end
            end
          end
        end

        describe 'sec' do
          describe 'enabled' do
            it 'is disabled by default' do
              expect(config.gitlab.rails.databases.sec.enabled).to be(false)
            end
          end

          describe 'use_main_database' do
            it 'is enabled by default' do
              expect(config.gitlab.rails.databases.sec.use_main_database).to be(true)
            end
          end

          describe '__enabled' do
            it 'is disabled by default' do
              expect(config.gitlab.rails.databases.sec.__enabled).to be(false)
            end

            context 'when config.gitlab.rails.multiple_databases is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'multiple_databases' => true
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.sec.__enabled).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.sec.enabled is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'sec' => {
                        'enabled' => true
                      }
                    }
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.sec.__enabled).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.sec.enabled is false' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'sec' => {
                        'enabled' => false
                      }
                    }
                  }
                }
              end

              it 'is disabled' do
                expect(config.gitlab.rails.databases.sec.__enabled).to be(false)
              end
            end
          end

          describe '__use_main_database' do
            it 'is enabled by default' do
              expect(config.gitlab.rails.databases.sec.__use_main_database).to be(true)
            end

            context 'when config.gitlab.rails.multiple_databases is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'multiple_databases' => 'true'
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.sec.__use_main_database).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.sec.enabled is true' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'sec' => {
                        'enabled' => true
                      }
                    }
                  }
                }
              end

              it 'is enabled' do
                expect(config.gitlab.rails.databases.sec.__enabled).to be(true)
              end
            end

            context 'when config.gitlab.rails.databases.sec.enabled is false' do
              before do
                yaml['khulnasoft'] = {
                  'rails' => {
                    'databases' => {
                      'sec' => {
                        'enabled' => false
                      }
                    }
                  }
                }
              end

              it 'is disabled' do
                expect(config.gitlab.rails.databases.sec.__enabled).to be(false)
              end
            end
          end
        end
      end

      describe 'topology_service' do
        describe '#enabled' do
          it 'defaults to true' do
            expect(config.gitlab.topology_service.enabled).to be(true)
          end
        end

        describe '#address' do
          it 'defaults to the localhost:grpc_port' do
            expect(config.gitlab.topology_service.address).to eq("kdk.example.com:9095")
          end
        end

        describe 'certificate files' do
          let(:certs_directory) { "/home/git/kdk/khulnasoft-topology-service/tmp/certs" }

          it 'they default to the certificate files in the temp directory' do
            expect(config.gitlab.topology_service.ca_file).to eq(Pathname.new(File.join(certs_directory, "ca-cert.pem")))
            expect(config.gitlab.topology_service.certificate_file).to eq(Pathname.new(File.join(certs_directory, "client-cert.pem")))
            expect(config.gitlab.topology_service.private_key_file).to eq(Pathname.new(File.join(certs_directory, "client-key.pem")))
          end
        end
      end

      describe 'cell' do
        describe '#cell_id' do
          it 'defaults to 1' do
            expect(config.gitlab.cell.id).to eq(1)
          end
        end
      end

      describe 'puma' do
        describe 'threads_min' do
          it 'is 1 by default' do
            expect(config.gitlab.rails.puma.threads_min).to be(1)
          end
        end

        describe '__threads_min' do
          context 'when running in clustered mode (workers > 0)' do
            before do
              yaml['khulnasoft'] = {
                'rails' => {
                  'puma' => {
                    'workers' => 2
                  }
                }
              }
            end

            it 'is 1 by default' do
              expect(config.gitlab.rails.puma.__threads_min).to be(1)
            end
          end

          context 'when running in single mode (workers == 0)' do
            before do
              yaml['khulnasoft'] = {
                'rails' => {
                  'puma' => {
                    'workers' => 0
                  }
                }
              }
            end

            it 'is equal to threads_max' do
              expect(config.gitlab.rails.puma.__threads_min).to be(config.gitlab.rails.puma.threads_max)
            end
          end
        end

        describe 'threads_max' do
          it 'is 4 by default' do
            expect(config.gitlab.rails.puma.threads_max).to be(4)
          end
        end

        describe '__threads_max' do
          let(:threads_max) { nil }

          before do
            yaml['khulnasoft'] = {
              'rails' => {
                'puma' => {
                  'threads_min' => 2,
                  'threads_max' => threads_max
                }
              }
            }
          end

          context 'when threads_max > threads_min' do
            let(:threads_max) { 3 }

            it 'is equal to threads_max' do
              expect(config.gitlab.rails.puma.__threads_max).to be(config.gitlab.rails.puma.threads_max)
            end
          end

          context 'when threads_max < threads_min' do
            let(:threads_max) { 1 }

            it 'is equal to threads_min' do
              expect(config.gitlab.rails.puma.__threads_max).to be(config.gitlab.rails.puma.threads_min)
            end
          end
        end

        describe 'workers' do
          it 'is 2 by default' do
            expect(config.gitlab.rails.puma.workers).to be(2)
          end
        end
      end

      describe '#allowed_hosts' do
        it 'returns empty array by default' do
          expect(config.gitlab.rails.allowed_hosts).to eq([])
        end
      end

      describe '#application_settings_cache_seconds' do
        it 'defaults to 60' do
          expect(config.gitlab.rails.application_settings_cache_seconds).to be(60)
        end
      end
    end

    describe 'rails_background_jobs' do
      describe 'verbose' do
        it 'is disabled by default' do
          expect(config.gitlab.rails_background_jobs.verbose?).to be(false)
        end
      end

      describe 'timeout' do
        it 'is 10 (half of config.kdk.runit_wait_secs) by default' do
          expect(config.gitlab.rails_background_jobs.timeout).to be(10)
        end

        context 'when customized' do
          before do
            yaml['khulnasoft'] = {
              'rails_background_jobs' => {
                'timeout' => 5
              }
            }
          end

          it 'is equal to 5' do
            expect(config.gitlab.rails_background_jobs.timeout).to be(5)
          end
        end
      end

      describe '#sidekiq_exporter_enabled' do
        it 'defaults to false' do
          expect(config.gitlab.rails_background_jobs.sidekiq_exporter_enabled).to be(false)
        end
      end

      describe '#sidekiq_exporter_port' do
        it 'defaults to 3807' do
          expect(config.gitlab.rails_background_jobs.sidekiq_exporter_port).to eq(3807)
        end
      end

      describe '#sidekiq_health_check_enabled' do
        it 'defaults to false' do
          expect(config.gitlab.rails_background_jobs.sidekiq_health_check_enabled).to be(false)
        end
      end

      describe '#sidekiq_health_check_port' do
        it 'defaults to 3907' do
          expect(config.gitlab.rails_background_jobs.sidekiq_health_check_port).to eq(3907)
        end
      end

      describe '#sidekiq_routing_rules' do
        it 'defaults to routing all to the default queue' do
          expect(config.gitlab.rails_background_jobs.sidekiq_routing_rules).to eq([["*", "default"]])
        end
      end
    end
  end

  describe 'k8s_agent' do
    describe 'enabled' do
      it 'is disabled by default' do
        expect(config.khulnasoft_k8s_agent.enabled).to be(false)
      end
    end

    describe 'auto_update' do
      it 'is enabled by default' do
        expect(config.khulnasoft_k8s_agent.auto_update).to be(true)
      end
    end

    describe 'agent_listen_network' do
      it 'is tcp by default' do
        expect(config.khulnasoft_k8s_agent.agent_listen_network).to eq('tcp')
      end
    end

    describe 'agent_listen_address' do
      it 'is 127.0.0.1:8150 by default' do
        expect(config.khulnasoft_k8s_agent.agent_listen_address).to eq('127.0.0.1:8150')
      end
    end

    describe '__agent_listen_url_path' do
      it 'is /-/kubernetes-agent by default' do
        expect(config.khulnasoft_k8s_agent.__agent_listen_url_path).to eq('/-/kubernetes-agent')
      end
    end

    describe 'private_api_listen_network' do
      it 'is tcp by default' do
        expect(config.khulnasoft_k8s_agent.private_api_listen_network).to eq('tcp')
      end
    end

    describe 'private_api_listen_address' do
      it 'is 127.0.0.1:8155 by default' do
        expect(config.khulnasoft_k8s_agent.private_api_listen_address).to eq('127.0.0.1:8155')
      end
    end

    describe 'k8s_api_listen_network' do
      it 'is tcp by default' do
        expect(config.khulnasoft_k8s_agent.k8s_api_listen_network).to eq('tcp')
      end
    end

    describe 'k8s_api_listen_address' do
      it 'is 127.0.0.1:8154 by default' do
        expect(config.khulnasoft_k8s_agent.k8s_api_listen_address).to eq('127.0.0.1:8154')
      end
    end

    describe '__k8s_api_listen_url_path' do
      it 'is /-/k8s-proxy by default' do
        expect(config.khulnasoft_k8s_agent.__k8s_api_listen_url_path).to eq('/-/k8s-proxy/')
      end
    end

    describe '__khulnasoft_address' do
      it 'is http://kdk.example.com:3333 by default' do
        expect(config.khulnasoft_k8s_agent.__khulnasoft_address).to eq('http://kdk.example.com:3333')
      end

      context 'when khulnasoft_http_router is disabled' do
        before do
          yaml['khulnasoft_http_router'] = { 'enabled' => false }
        end

        it 'is http://kdk.example.com:3000 by default' do
          expect(config.khulnasoft_k8s_agent.__khulnasoft_address).to eq('http://kdk.example.com:3000')
        end
      end
    end

    describe '__khulnasoft_external_url' do
      let(:yaml) do
        {
          'nginx' => { 'enabled' => nginx_enabled }
        }
      end

      context 'when nginx is enabled' do
        let(:nginx_enabled) { true }

        it { expect(config.khulnasoft_k8s_agent.__khulnasoft_external_url).to eq("http://#{config.nginx.__listen_address}") }
      end

      context 'when nginx is disabled' do
        let(:nginx_enabled) { false }

        it { expect(config.khulnasoft_k8s_agent.__khulnasoft_external_url).to eq(config.khulnasoft_k8s_agent.__khulnasoft_address) }
      end
    end

    describe '__url_for_agentk' do
      let(:https_enabled) { nil }

      let(:yaml) do
        {
          'nginx' => { 'enabled' => nginx_enabled },
          'https' => { 'enabled' => https_enabled }
        }
      end

      context 'when nginx is not enabled' do
        let(:nginx_enabled) { false }

        it 'is grpc://127.0.0.1:8150' do
          expect(config.khulnasoft_k8s_agent.__url_for_agentk).to eq('grpc://127.0.0.1:8150')
        end
      end

      context 'when nginx is enabled' do
        let(:nginx_enabled) { true }

        context 'but https is not enabled' do
          let(:https_enabled) { false }

          it 'is ws://127.0.0.1:8080/-/kubernetes-agent' do
            expect(config.khulnasoft_k8s_agent.__url_for_agentk).to eq('ws://127.0.0.1:8080/-/kubernetes-agent')
          end
        end

        context 'and https is enabled' do
          let(:https_enabled) { true }

          it 'is wss://127.0.0.1:8080/-/kubernetes-agent' do
            expect(config.khulnasoft_k8s_agent.__url_for_agentk).to eq('wss://127.0.0.1:8080/-/kubernetes-agent')
          end
        end

        context 'when khulnasoft_http_router is disabled' do
          before do
            yaml['khulnasoft_http_router'] = { 'enabled' => false }
          end

          context 'but https is not enabled' do
            let(:https_enabled) { false }

            it 'is ws://127.0.0.1:3000/-/kubernetes-agent' do
              expect(config.khulnasoft_k8s_agent.__url_for_agentk).to eq('ws://127.0.0.1:3000/-/kubernetes-agent')
            end
          end

          context 'and https is enabled' do
            let(:https_enabled) { true }

            it 'is wss://127.0.0.1:3000/-/kubernetes-agent' do
              expect(config.khulnasoft_k8s_agent.__url_for_agentk).to eq('wss://127.0.0.1:3000/-/kubernetes-agent')
            end
          end
        end
      end
    end

    describe 'internal_api_listen_network' do
      it 'is tcp by default' do
        expect(config.khulnasoft_k8s_agent.internal_api_listen_network).to eq('tcp')
      end
    end

    describe 'internal_api_listen_address' do
      it 'is 127.0.0.1:8153 by default' do
        expect(config.khulnasoft_k8s_agent.internal_api_listen_address).to eq('127.0.0.1:8153')
      end
    end

    describe '__internal_api_url' do
      let(:yaml) do
        {
          'khulnasoft_k8s_agent' => { 'internal_api_listen_network' => internal_api_listen_network }
        }
      end

      context 'when internal_api_listen_network is tcp' do
        let(:internal_api_listen_network) { 'tcp' }

        it 'is grpc://127.0.0.1:8153' do
          expect(config.khulnasoft_k8s_agent.__internal_api_url).to eq('grpc://127.0.0.1:8153')
        end
      end

      context 'when internal_api_listen_network is unix' do
        let(:internal_api_listen_network) { 'unix' }

        it 'is unix://127.0.0.1:8153' do
          expect(config.khulnasoft_k8s_agent.__internal_api_url).to eq('unix://127.0.0.1:8153')
        end
      end
    end

    describe '__k8s_api_url' do
      let(:https_enabled) { nil }

      let(:yaml) do
        {
          'nginx' => { 'enabled' => nginx_enabled },
          'https' => { 'enabled' => https_enabled }
        }
      end

      context 'when nginx is not enabled' do
        let(:nginx_enabled) { false }

        it 'is http://127.0.0.1:8154' do
          expect(config.khulnasoft_k8s_agent.__k8s_api_url).to eq('http://127.0.0.1:8154')
        end
      end

      context 'when nginx is enabled' do
        let(:nginx_enabled) { true }

        context 'but https is not enabled' do
          let(:https_enabled) { false }

          it 'is http://127.0.0.1:8080/-/k8s-proxy/' do
            expect(config.khulnasoft_k8s_agent.__k8s_api_url).to eq('http://127.0.0.1:8080/-/k8s-proxy/')
          end
        end

        context 'and https is enabled' do
          let(:https_enabled) { true }

          it 'is https://127.0.0.1:8080/-/k8s-proxy/' do
            expect(config.khulnasoft_k8s_agent.__k8s_api_url).to eq('https://127.0.0.1:8080/-/k8s-proxy/')
          end
        end

        context 'when khulnasoft_http_router is disabled' do
          before do
            yaml['khulnasoft_http_router'] = { 'enabled' => false }
          end

          context 'but https is not enabled' do
            let(:https_enabled) { false }

            it 'is http://127.0.0.1:3000/-/k8s-proxy/' do
              expect(config.khulnasoft_k8s_agent.__k8s_api_url).to eq('http://127.0.0.1:3000/-/k8s-proxy/')
            end
          end

          context 'and https is enabled' do
            let(:https_enabled) { true }

            it 'is https://127.0.0.1:3000/-/k8s-proxy/' do
              expect(config.khulnasoft_k8s_agent.__k8s_api_url).to eq('https://127.0.0.1:3000/-/k8s-proxy/')
            end
          end
        end
      end
    end

    describe '__command' do
      subject { config.khulnasoft_k8s_agent.__command }

      it { is_expected.to eq 'khulnasoft-k8s-agent/build/kdk/bin/kas_race' }

      context 'when run_from_source is true' do
        let(:yaml) { { 'khulnasoft_k8s_agent' => { 'run_from_source' => true } } }

        it { is_expected.to eq('support/exec-cd khulnasoft-k8s-agent go run -race cmd/kas/main.go') }
      end
    end

    describe '__websocket_token_secret_file' do
      subject { config.khulnasoft_k8s_agent.__websocket_token_secret_file }

      it { is_expected.to eq '/home/git/kdk/gitlab-kas-websocket-token-secret' }
    end

    describe '__autoflow_temporal_workflow_data_encryption_secret_file' do
      subject { config.khulnasoft_k8s_agent.autoflow.temporal.workflow_data_encryption.__secret_key_file }

      it { is_expected.to eq '/home/git/kdk/gitlab-kas-autoflow-temporal-workflow-data-encryption-secret' }
    end

    describe 'tracing' do
      it 'is disabled by default' do
        expect(config.khulnasoft_k8s_agent.otlp_endpoint).to eq('')
        expect(config.khulnasoft_k8s_agent.otlp_token_secret_file).to eq('')
        expect(config.khulnasoft_k8s_agent.otlp_ca_certificate_file).to be('')
      end
    end

    describe 'autoflow' do
      it 'is disabled by default' do
        expect(config.khulnasoft_k8s_agent.autoflow.enabled).to be(false)
      end

      describe '__http_client' do
        it 'allows listen address' do
          expect(config.khulnasoft_k8s_agent.autoflow.__http_client.allowed_ips).to include('127.0.0.1')
        end

        it 'allows listen port' do
          expect(config.khulnasoft_k8s_agent.autoflow.__http_client.allowed_ports).to include(3000)
        end

        it 'allows standard HTTP and HTTPS ports' do
          expect(config.khulnasoft_k8s_agent.autoflow.__http_client.allowed_ports).to include(80, 443)
        end
      end

      describe 'temporal' do
        it 'configures Temporal dev server host port by default' do
          expect(config.khulnasoft_k8s_agent.autoflow.temporal.host_port).to eq('localhost:7233')
        end

        it 'configures Temporal dev server namespace by default' do
          expect(config.khulnasoft_k8s_agent.autoflow.temporal.namespace).to eq('default')
        end
      end
    end
  end

  describe 'nginx' do
    describe '#__listen_address' do
      let(:yaml) do
        {
          'port' => 1234,
          'nginx' => { 'listen_address' => 'localhost' }
        }
      end

      it 'is set to ip and default nginx port' do
        expect(config.nginx.__listen_address).to eq('localhost:8080')
      end

      context 'when khulnasoft_http_router is disabled' do
        before do
          yaml['khulnasoft_http_router'] = { 'enabled' => false }
        end

        it 'is set to ip and port' do
          expect(config.nginx.__listen_address).to eq('localhost:1234')
        end
      end
    end

    describe '#__request_buffering_off_routes' do
      it 'has some defailt routes' do
        expected_routes = [
          '/api/v\d/jobs/\d+/artifacts$',
          '\.git/git-receive-pack$',
          '\.git/ssh-upload-pack$',
          '\.git/ssh-receive-pack$',
          '\.git/gitlab-lfs/objects',
          '\.git/info/lfs/objects/batch$'
        ]

        expect(config.nginx.__request_buffering_off_routes).to eq(expected_routes)
      end
    end
  end

  describe 'smartcard' do
    it 'is disabled by default' do
      expect(config.smartcard.enabled).to be(false)
    end

    it 'has a hostname by default' do
      expect(config.smartcard.hostname).to eq('smartcard.kdk.test')
    end

    it 'uses managed port by default' do
      default_port = KDK::PortManager.new(config: config).default_port_for_service('smartcard_nginx')
      expect(config.smartcard.port).to eq(default_port)
    end

    it 'uses san_extensions by default' do
      expect(config.smartcard.san_extensions).to be(true)
    end

    describe 'ssl' do
      it 'provides default cert' do
        expect(config.smartcard.ssl.certificate).to eq('smartcard.kdk.test.pem')
      end

      it 'provides default key' do
        expect(config.smartcard.ssl.key).to eq('smartcard.kdk.test-key.pem')
      end

      it 'provides example client cert CA' do
        expect(config.smartcard.ssl.client_cert_ca).to eq('/mkcert/rootCA.pem')
      end
    end
  end

  describe 'khulnasoft_elasticsearch_indexer' do
    describe '#__dir' do
      it 'returns the KhulnaSoft directory' do
        expect(config.khulnasoft_elasticsearch_indexer.__dir).to eq(Pathname.new('/home/git/kdk/gitlab-elasticsearch-indexer'))
      end
    end
  end

  describe 'load_balancing' do
    it 'disabled by default' do
      expect(config.load_balancing.enabled).to be false
    end
  end

  describe 'khulnasoft_ui' do
    describe 'enabled' do
      it 'is disabled by default' do
        expect(config.khulnasoft_ui.enabled).to be(false)
      end
    end

    describe 'auto_update' do
      it 'is enabled by default' do
        expect(config.khulnasoft_ui.auto_update).to be(true)
      end
    end
  end

  describe 'rails_web' do
    describe 'enabled' do
      it 'is enabled by default' do
        expect(config.rails_web.enabled).to be(true)
      end
    end
  end

  describe 'vite' do
    describe '#enabled' do
      it 'is false by default' do
        expect(config.vite.enabled).to be false
      end
    end

    describe '#port' do
      it 'is 3038 by default' do
        expect(config.vite.port).to be 3038
      end
    end

    describe '#hot_module_reloading' do
      it 'is enabled by default' do
        expect(config.vite.hot_module_reloading?).to be true
      end
    end
  end

  describe 'webpack' do
    describe '#enabled' do
      it 'is true by default' do
        expect(config.webpack.enabled).to be true
      end
    end

    describe '#incremental' do
      it 'is true by default' do
        expect(config.webpack.incremental).to be true
      end
    end

    describe '#incremental_ttl' do
      it 'is 30 days by default' do
        expect(config.webpack.incremental_ttl).to be 30
      end
    end

    describe '#vendor_dll' do
      it 'is false by default' do
        expect(config.webpack.vendor_dll).to be false
      end
    end

    describe '#static' do
      it 'is false by default' do
        expect(config.webpack.static).to be false
      end
    end

    describe '#sourcemaps' do
      it 'is true by default' do
        expect(config.webpack.sourcemaps).to be true
      end
    end

    describe '#live_reload' do
      it 'is true by default' do
        expect(config.webpack.live_reload).to be true
      end
    end

    describe '#public_address' do
      it 'is empty string by default' do
        expect(config.webpack.public_address).to be ""
      end
    end

    describe '#allowed_hosts' do
      it 'returns empty array by default' do
        expect(config.webpack.allowed_hosts).to eq []
      end
    end

    describe '#__dev_server_public' do
      context 'when live_reload is disabled' do
        before do
          yaml['webpack'] = { 'live_reload' => false }
        end

        it 'is empty string' do
          expect(config.webpack.__dev_server_public).to be ""
        end
      end

      context 'when public_address is set' do
        before do
          yaml['webpack'] = { 'public_address' => "wss://3808-example.gitpod.io/ws" }
        end

        it 'is equals the public_address value' do
          expect(config.webpack.__dev_server_public).to be config.webpack.public_address
        end
      end

      context 'when nginx is enabled (with http)' do
        before do
          yaml['nginx'] = { 'enabled' => true }
        end

        it 'is set to the nginx proxy with ws' do
          expect(config.webpack.__dev_server_public).to eq "ws://#{config.nginx.__listen_address}/_hmr/"
        end
      end

      context 'when nginx is enabled (with https)' do
        before do
          yaml['nginx'] = { 'enabled' => true }
          yaml['https'] = { 'enabled' => true }
        end

        it 'is set to the nginx proxy with wss' do
          expect(config.webpack.__dev_server_public).to eq "wss://#{config.nginx.__listen_address}/_hmr/"
        end
      end
    end
  end

  describe 'action_cable' do
    describe '#worker_pool_size' do
      it 'returns 4 by deftault' do
        expect(config.action_cable.worker_pool_size).to eq 4
      end
    end
  end

  describe 'registry' do
    describe '#version' do
      context 'when no version is specified' do
        it 'returns the default version' do
          expect(config.registry.version).to eq('v4.14.0-gitlab')
        end
      end
    end

    describe '#api_host' do
      it 'returns the default hostname' do
        expect(config.registry.api_host).to eq('kdk.example.com')
      end
    end

    describe '#port' do
      it 'returns 5100 by default' do
        expect(config.registry.port).to eq(5100)
      end
    end

    describe '#__listen' do
      it 'returns kdk.example.com:5100 by default' do
        expect(config.registry.__listen).to eq('kdk.example.com:5100')
      end
    end

    describe '#listen_address' do
      it 'returns 127.0.0.1 by default' do
        expect(config.registry.listen_address).to eq('127.0.0.1')
      end
    end

    describe '#notifications_enabled' do
      it 'returns false' do
        expect(config.registry.notifications_enabled).to be false
      end
    end

    describe '#read_only_maintenance_enabled' do
      it 'returns false' do
        expect(config.registry.read_only_maintenance_enabled).to be false
      end
    end

    describe '#__registry_build_bin_path' do
      it 'is /home/git/kdk/container-registry/bin/registry by default' do
        expect(config.registry.__registry_build_bin_path).to eq(Pathname.new('/home/git/kdk/container-registry/bin/registry'))
      end
    end

    describe 'database' do
      describe '#enabled' do
        it 'is false by default' do
          expect(config.registry.database.enabled).to be(false)
        end
      end

      describe '#host' do
        it 'is postgresql host by default' do
          expect(config.registry.database.host).to eq(default_config.postgresql.dir.to_s)
        end

        context 'for a Geo secondary' do
          let!(:yaml) do
            {
              'geo' => {
                'enabled' => true,
                'secondary' => true
              }
            }
          end

          it 'is default geo secondary postgresql host by default' do
            expect(config.registry.database.host).to eq('/home/git/kdk/postgresql-geo')
          end
        end
      end

      describe '#port' do
        it 'is 5432 by default' do
          expect(config.registry.database.port).to eq(5432)
        end

        context 'for a Geo secondary' do
          let!(:yaml) do
            {
              'geo' => {
                'enabled' => true,
                'secondary' => true
              }
            }
          end

          it 'is default geo secondary postgresql port by default' do
            expect(config.registry.database.port).to eq(5431)
          end
        end
      end

      describe '#dbname' do
        it 'is registry_dev by default' do
          expect(config.registry.database.dbname).to eq('registry_dev')
        end
      end

      describe '#sslmode' do
        it 'is disabled by default' do
          expect(config.registry.database.sslmode).to eq('disable')
        end
      end
    end
  end

  describe 'object_store' do
    describe '#host' do
      it 'returns the default hostname' do
        expect(config.object_store.host).to eq('127.0.0.1')
      end
    end

    describe '#connection' do
      context 'default settings' do
        let(:default_connection) do
          {
            'provider' => 'AWS',
            'aws_access_key_id' => 'minio',
            'aws_secret_access_key' => 'kdk-minio',
            'region' => 'kdk',
            'endpoint' => "http://127.0.0.1:9000",
            'path_style' => true
          }
        end

        it 'returns the default Minio connection parameters' do
          expect(config.object_store.connection).to eq(default_connection)
        end

        it 'configures Gitaly backup URL' do
          expect(config.gitaly.backup.go_cloud_url).to eq("s3://gitaly-backups?awssdk=v2&disable_https=true&use_path_style=true&region=kdk&endpoint=http%3A%2F%2F127.0.0.1%3A9000")
        end
      end

      context 'with external S3 provider' do
        let(:s3_connection) do
          {
            'provider' => 'AWS',
            'aws_access_key_id' => 'test_access_key',
            'aws_secret_access_key' => 'secret'
          }
        end

        before do
          yaml.merge!(
            {
              'object_store' => {
                'enabled' => true,
                'connection' => s3_connection
              }
            }
          )
        end

        it 'configures the S3 provider' do
          expect(config.object_store.enabled?).to be true
          expect(config.object_store.connection).to eq(s3_connection)
        end

        it 'configures Gitaly backup URL' do
          expect(config.gitaly.backup.go_cloud_url).to eq("s3://gitaly-backups?awssdk=v2&disable_https=false&use_path_style=false")
        end
      end

      context 'with AzureRM provider' do
        let(:azure_connection) do
          {
            'provider' => 'AzureRM',
            'azure_storage_account_name' => 'azure-account',
            'azure_storage_access_key' => '12345'
          }
        end

        before do
          yaml.merge!(
            {
              'object_store' => {
                'enabled' => true,
                'connection' => azure_connection
              }
            }
          )
        end

        it 'configures the Azure provider' do
          expect(config.object_store.enabled?).to be true
          expect(config.object_store.connection).to eq(azure_connection)
        end

        it 'configures Gitaly backup URL' do
          expect(config.gitaly.backup.go_cloud_url).to eq("azblob://gitaly-backups?storage_account=azure-account")
        end
      end

      context 'with Google provider' do
        let(:google_connection) do
          {
            'provider' => 'Google',
            'google_application_default' => true
          }
        end

        before do
          yaml.merge!(
            {
              'object_store' => {
                'enabled' => true,
                'connection' => google_connection
              }
            }
          )
        end

        it 'configures the Google provider' do
          expect(config.object_store.enabled?).to be true
          expect(config.object_store.connection).to eq(google_connection)
        end

        it 'configures Gitaly backup URL' do
          expect(config.gitaly.backup.go_cloud_url).to eq("gs://gitaly-backups")
        end
      end
    end

    describe '#backup_remote_directory' do
      it 'is empty by default' do
        expect(config.object_store.backup_remote_directory).to eq('')
      end
    end

    describe '#console_port' do
      it 'is set to 9001 by default' do
        expect(config.object_store.console_port).to eq(9002)
      end

      context 'with a custom port' do
        before do
          yaml.merge!('object_store' => { 'console_port' => 1337 })
        end

        it 'is set to the custom value' do
          expect(config.object_store.console_port).to eq(1337)
        end
      end
    end
  end

  describe 'omniauth' do
    context 'defaults' do
      it 'returns false' do
        expect(config.omniauth.google_oauth2.enabled).to be false
        expect(config.omniauth.group_saml.enabled).to be false
        expect(config.omniauth.github.enabled).to be false
      end
    end

    context 'when group SAML is disabled' do
      it 'returns false' do
        expect(config.omniauth.group_saml.enabled).to be false
      end
    end

    context 'when group SAML is enabled' do
      let(:group_saml_enabled) { true }

      it 'returns true' do
        expect(config.omniauth.group_saml.enabled).to be true
      end
    end

    context 'when GitHub is enabled' do
      let(:omniauth_config) { { 'github' => { 'enabled' => true, 'client_id' => '12345', 'client_secret' => 'mysecret' } } }

      it 'returns true' do
        expect(config.omniauth.github.enabled).to be true
        expect(config.omniauth.github.client_id).to eq('12345')
        expect(config.omniauth.github.client_secret).to eq('mysecret')
      end
    end

    context 'when OpenID Connect is enabled' do
      let(:omniauth_config) { { 'openid_connect' => { 'enabled' => true, 'args' => { 'scope' => 'openid' } } } }

      it 'returns true' do
        expect(config.omniauth.openid_connect.enabled).to be true
        expect(config.omniauth.openid_connect.args).to eq({ 'scope' => 'openid' })
      end
    end
  end

  describe 'khulnasoft_pages' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.khulnasoft_pages.enabled).to be(false)
        expect(config.khulnasoft_pages.enabled?).to be(false)
      end
    end

    describe '#host' do
      context 'when host is not specified' do
        it 'returns the default hostname' do
          expect(config.khulnasoft_pages.host).to eq('127.0.0.1.nip.io')
        end
      end

      context 'when host is specified' do
        let(:yaml) do
          {
            'khulnasoft_pages' => { 'host' => 'pages.localhost' }
          }
        end

        it 'returns the configured hostname' do
          expect(config.khulnasoft_pages.host).to eq('pages.localhost')
        end
      end
    end

    describe '#port' do
      context 'when port is not specified' do
        it 'returns the default port' do
          expect(config.khulnasoft_pages.port).to eq(3010)
        end
      end

      context 'when port is specified' do
        let(:yaml) do
          {
            'khulnasoft_pages' => { 'port' => 5555 }
          }
        end

        it 'returns the configured port' do
          expect(config.khulnasoft_pages.port).to eq(5555)
        end
      end

      describe '#verbose' do
        it 'defaults to false' do
          expect(config.khulnasoft_pages.verbose).to be(false)
          expect(config.khulnasoft_pages.verbose?).to be(false)
        end

        context 'when verbose is specified' do
          let(:yaml) do
            {
              'khulnasoft_pages' => { 'verbose' => true }
            }
          end

          it 'returns the configured port' do
            expect(config.khulnasoft_pages.verbose).to be(true)
          end
        end
      end

      describe '#propagate_correlation_id' do
        it 'defaults to false' do
          expect(config.khulnasoft_pages.propagate_correlation_id).to be(false)
          expect(config.khulnasoft_pages.propagate_correlation_id?).to be(false)
        end

        context 'when propagate_correlation_id is specified' do
          let(:yaml) do
            {
              'khulnasoft_pages' => { 'propagate_correlation_id' => true }
            }
          end

          it 'returns the configured port' do
            expect(config.khulnasoft_pages.propagate_correlation_id).to be(true)
          end
        end
      end
    end

    describe '#__uri' do
      it 'returns 127.0.0.1.nip.io:3010' do
        expect(config.khulnasoft_pages.__uri.to_s).to eq('127.0.0.1.nip.io:3010')
      end
    end

    describe '#access_control' do
      it 'defaults to false' do
        expect(config.khulnasoft_pages.access_control?).to be(false)
      end

      context 'when access_control is enabled' do
        let(:yaml) do
          {
            'khulnasoft_pages' => { 'access_control' => true, 'auth_client_id' => 'client_id', 'auth_client_secret' => 'client_secret', 'auth_scope' => 'read_api' }
          }
        end

        it 'configures auth correctly' do
          expect(config.khulnasoft_pages.access_control?).to be(true)
          expect(config.khulnasoft_pages.auth_client_id).to eq('client_id')
          expect(config.khulnasoft_pages.auth_client_secret).to eq('client_secret')
          expect(config.khulnasoft_pages.auth_scope).to eq('read_api')
          expect(config.khulnasoft_pages.__auth_secret.length).to eq(32)
          expect(config.khulnasoft_pages.__auth_redirect_uri).to eq('http://127.0.0.1.nip.io:3010/auth')
        end
      end
    end

    describe '#enable_custom_domains' do
      it 'defaults to false' do
        expect(config.khulnasoft_pages.enable_custom_domains?).to be(false)
      end

      context 'when enable_custom_domains is enabled' do
        let(:yaml) do
          {
            'khulnasoft_pages' => { 'enable_custom_domains' => true }
          }
        end

        it 'configures custom domains correctly' do
          expect(config.khulnasoft_pages.enable_custom_domains?).to be(true)
        end
      end
    end

    describe '#auth_scope' do
      it 'defaults to api' do
        expect(config.khulnasoft_pages.auth_scope).to eq('api')
      end

      context 'when auth_scope is set' do
        let(:yaml) do
          {
            'khulnasoft_pages' => { 'access_control' => true, 'auth_scope' => 'read_api' }
          }
        end

        it 'configures auth scope' do
          expect(config.khulnasoft_pages.auth_scope).to eq('read_api')
        end
      end
    end
  end

  describe 'prometheus' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.prometheus.enabled).to be(false)
      end
    end

    describe '#__uri' do
      it 'returns http://kdk.example.com:9090 by default' do
        expect(config.prometheus.__uri.to_s).to eq('http://kdk.example.com:9090')
      end
    end

    describe '#port' do
      it 'defaults to 9090' do
        expect(config.prometheus.port).to eq(9090)
      end
    end

    describe '#gitaly_exporter_port' do
      it 'defaults to 9236' do
        expect(config.prometheus.gitaly_exporter_port).to eq(9236)
      end
    end

    describe '#praefect_exporter_port' do
      it 'defaults to 10101' do
        expect(config.prometheus.praefect_exporter_port).to eq(10101)
      end
    end

    describe '#workhorse_exporter_port' do
      it 'defaults to 9229' do
        expect(config.prometheus.workhorse_exporter_port).to eq(9229)
      end
    end

    describe '#khulnasoft_shell_exporter_port' do
      it 'defaults to 9122' do
        expect(config.prometheus.khulnasoft_shell_exporter_port).to eq(9122)
      end
    end

    describe '#khulnasoft_ai_gateway_exporter_port' do
      it 'defaults to 8082' do
        expect(config.prometheus.khulnasoft_ai_gateway_exporter_port).to eq(8082)
      end
    end

    describe '__add_host_flags' do
      before do
        yaml['prometheus'] = {
          'enabled' => 'true'
        }
      end

      context 'when extra_hosts is empty' do
        before do
          yaml['prometheus']['extra_hosts'] = []
        end

        it 'returns an empty string' do
          flags = config.prometheus.__add_host_flags

          expect(flags).to be_a(String)
          expect(flags).to be_empty
        end
      end

      context 'when extra_hosts contains a single item' do
        before do
          yaml['prometheus']['extra_hosts'] = ['kdk.test:172.16.123.1']
        end

        it 'returns a single flag' do
          expect(config.prometheus.__add_host_flags).to eq("--add-host='kdk.test:172.16.123.1'")
        end
      end

      context 'when extra_hosts contains multiple items' do
        before do
          yaml['prometheus']['extra_hosts'] =
            ['kdk.test:172.16.123.1', 'kdk.test:192.168.65.2', 'registry.kdk.test:172.17.0.4']
        end

        it 'returns multiple flags separated by spaces' do
          flags = config.prometheus.__add_host_flags

          expect(flags).to eq("--add-host='kdk.test:172.16.123.1' --add-host='kdk.test:192.168.65.2' --add-host='registry.kdk.test:172.17.0.4'")
        end
      end
    end
  end

  describe 'grafana' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.grafana.enabled).to be(false)
        expect(config.grafana.enabled?).to be(false)
      end
    end

    describe '#__uri' do
      it 'returns http://kdk.example.com:4000 by default' do
        expect(config.grafana.__uri.to_s).to eq('http://kdk.example.com:4000')
      end
    end

    describe '#port' do
      it 'defaults to 4000' do
        expect(config.grafana.port).to eq(4000)
      end
    end
  end

  describe 'kdk' do
    describe '#debug' do
      it 'defaults to false' do
        expect(config.kdk.debug?).to be(false)
      end
    end

    describe '#auto_reconfigure' do
      it 'defaults to true' do
        expect(config.kdk.auto_reconfigure).to be(true)
        expect(config.kdk.auto_reconfigure?).to be(true)
      end
    end

    describe '#auto_rebase_projects' do
      it 'defaults to false' do
        expect(config.kdk.auto_rebase_projects?).to be(false)
      end
    end

    describe '#use_bash_shim' do
      it 'defaults to false' do
        expect(config.kdk.use_bash_shim?).to be(false)
      end
    end

    describe '#runit_wait_secs' do
      it 'is 20 secs by default' do
        expect(config.kdk.runit_wait_secs).to eq(20)
      end
    end

    describe '#start_hooks' do
      describe '#before' do
        it 'is an empty array by default' do
          expect(config.kdk.start_hooks.before).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'kdk' => { 'start_hooks' => { 'before' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.kdk.start_hooks.before).to eq(['uptime'])
          end
        end
      end

      describe '#after' do
        it 'is an empty array by default' do
          expect(config.kdk.start_hooks.after).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'kdk' => { 'start_hooks' => { 'after' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.kdk.start_hooks.after).to eq(['uptime'])
          end
        end
      end
    end

    describe '#stop_hooks' do
      describe '#before' do
        it 'is an empty array by default' do
          expect(config.kdk.stop_hooks.before).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'kdk' => { 'stop_hooks' => { 'before' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.kdk.stop_hooks.before).to eq(['uptime'])
          end
        end
      end

      describe '#after' do
        it 'is an empty array by default' do
          expect(config.kdk.stop_hooks.after).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'kdk' => { 'stop_hooks' => { 'after' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.kdk.stop_hooks.after).to eq(['uptime'])
          end
        end
      end
    end

    describe '#update_hooks' do
      describe '#before' do
        it 'has spring stop || true hook by default' do
          expect(config.kdk.update_hooks.before).to eq(['support/exec-cd gitlab bin/spring stop || true'])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'kdk' => { 'update_hooks' => { 'before' => ['uptime'] } } }
          end

          it 'has spring stop || true hook and then our hooks also' do
            expect(config.kdk.update_hooks.before).to eq(['uptime', 'support/exec-cd gitlab bin/spring stop || true'])
          end
        end
      end

      describe '#after' do
        it 'is an empty array by default' do
          expect(config.kdk.update_hooks.after).to eq([])
        end

        context 'with custom hooks defined' do
          let(:yaml) do
            { 'kdk' => { 'update_hooks' => { 'after' => ['uptime'] } } }
          end

          it 'replaces hooks with ours' do
            expect(config.kdk.update_hooks.after).to eq(['uptime'])
          end
        end
      end
    end
  end

  describe 'tracer' do
    describe 'build_tags' do
      it "is 'tracer_static tracer_static_jaeger' by default" do
        expect(config.tracer.build_tags).to eq('tracer_static tracer_static_jaeger')
      end
    end

    describe 'jaeger' do
      subject(:jaeger) { config.tracer.jaeger }

      describe 'enabled' do
        it 'is disabled by default' do
          expect(jaeger.enabled).to be(false)
          expect(jaeger.enabled?).to be(false)
        end
      end

      describe 'version' do
        it 'is 1.21.0 by default' do
          expect(jaeger.version).to eq('1.21.0')
        end
      end

      describe 'listen_address' do
        it 'is config.hostname by default' do
          expect(jaeger.listen_address).to eq(config.hostname)
        end
      end

      describe '__tracer_url' do
        it { expect(jaeger.__tracer_url).to eq("opentracing://jaeger?http_endpoint=http%3A%2F%2F#{jaeger.listen_address}%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1") }
      end

      describe '__search_url' do
        it { expect(jaeger.__search_url).to eq("http://#{jaeger.listen_address}:16686/search?service={{ service }}&tags=%7B%22correlation_id%22%3A%22{{ correlation_id }}%22%7D") }
      end
    end
  end

  describe 'asdf' do
    describe 'opt_out' do
      it 'is disabled by default' do
        expect(config.asdf.opt_out).to be(false)
        expect(config.asdf.opt_out?).to be(false)
      end
    end

    describe '__available?' do
      let(:yaml) do
        { 'asdf' => { 'opt_out' => asdf_opt_out } }
      end

      before do
        allow(KDK::Dependencies).to receive(:config).and_return(config)
      end

      context 'when asdf.opt_out? is true' do
        let(:asdf_opt_out) { true }

        it 'returns false' do
          expect(config.asdf.__available?).to be(false)
        end
      end

      context 'when asdf.opt_out? is false' do
        let(:asdf_opt_out) { false }

        before do
          stub_env('ASDF_DIR', nil)
        end

        context 'but asdf is not installed / configured' do
          it 'returns false' do
            allow(KDK::Dependencies).to receive(:asdf_available?).and_return(false)

            expect(config.asdf.__available?).to be(false)
          end
        end

        context 'and asdf is installed / configured' do
          it 'returns true' do
            allow(KDK::Dependencies).to receive(:asdf_available?).and_return(true)

            expect(config.asdf.__available?).to be(true)
          end
        end
      end
    end
  end

  describe 'docs_khulnasoft_com' do
    describe 'enabled' do
      it 'is disabled by default' do
        expect(config.docs_khulnasoft_com.enabled).to be(false)
        expect(config.docs_khulnasoft_com.enabled?).to be(false)
        expect(config.docs_khulnasoft_com?).to be(false)
      end
    end

    describe 'auto_update' do
      it 'is enabled by default' do
        expect(config.docs_khulnasoft_com.auto_update).to be(true)
        expect(config.docs_khulnasoft_com.auto_update?).to be(true)
      end
    end

    describe '#port' do
      context 'when port is not specified' do
        it 'returns the default port' do
          expect(config.docs_khulnasoft_com.port).to eq(1313)
        end
      end

      context 'when port is specified' do
        let(:yaml) do
          {
            'docs_khulnasoft_com' => { 'port' => 5555 }
          }
        end

        it 'returns the configured port' do
          expect(config.docs_khulnasoft_com.port).to eq(5555)
        end
      end
    end

    describe 'khulnasoft_runner' do
      describe 'enabled' do
        it 'is disabled by default' do
          expect(config.khulnasoft_runner.enabled).to be(false)
          expect(config.khulnasoft_runner.enabled?).to be(false)
        end
      end

      describe 'auto_update' do
        it 'is enabled by default' do
          expect(config.khulnasoft_runner.auto_update).to be(true)
          expect(config.khulnasoft_runner.auto_update?).to be(true)
        end
      end
    end

    describe 'omnibus_gitlab' do
      describe 'enabled' do
        it 'is disabled by default' do
          expect(config.omnibus_gitlab.enabled).to be(false)
          expect(config.omnibus_gitlab.enabled?).to be(false)
        end
      end

      describe 'auto_update' do
        it 'is enabled by default' do
          expect(config.omnibus_gitlab.auto_update).to be(true)
          expect(config.omnibus_gitlab.auto_update?).to be(true)
        end
      end
    end

    describe 'charts_gitlab' do
      describe 'enabled' do
        it 'is disabled by default' do
          expect(config.charts_gitlab.enabled).to be(false)
          expect(config.charts_gitlab.enabled?).to be(false)
        end
      end

      describe 'auto_update' do
        it 'is enabled by default' do
          expect(config.charts_gitlab.auto_update).to be(true)
          expect(config.charts_gitlab.auto_update?).to be(true)
        end
      end
    end

    describe 'khulnasoft_operator' do
      describe 'enabled' do
        it 'is disabled by default' do
          expect(config.khulnasoft_operator.enabled).to be(false)
          expect(config.khulnasoft_operator.enabled?).to be(false)
        end
      end

      describe 'auto_update' do
        it 'is enabled by default' do
          expect(config.khulnasoft_operator.auto_update).to be(true)
          expect(config.khulnasoft_operator.auto_update?).to be(true)
        end
      end
    end
  end

  describe 'packages' do
    describe '__dpkg_deb_path' do
      before do
        allow(KDK::Machine).to receive(:platform).and_return(fake_platform)
      end

      context 'on a macOS system' do
        let(:fake_platform) { 'darwin' }

        before do
          allow(File).to receive(:exist?).and_return(false)
          allow(File).to receive(:exist?).with(brew_path).and_return(true)
        end

        context 'with Intel' do
          let(:brew_path) { '/usr/local/bin/brew' }

          it 'returns /usr/local/bin/dpkg-deb' do
            expect(config.packages.__dpkg_deb_path.to_s).to eq('/usr/local/bin/dpkg-deb')
          end
        end

        context 'with Apple Silicon' do
          let(:brew_path) { '/opt/homebrew/bin/brew' }

          it 'returns /opt/homebrew/bin/dpkg-deb' do
            expect(config.packages.__dpkg_deb_path.to_s).to eq('/opt/homebrew/bin/dpkg-deb')
          end
        end
      end

      context 'on a Linux system' do
        let(:fake_platform) { 'linux' }

        it 'returns /usr/bin/dpkg-deb' do
          expect(config.packages.__dpkg_deb_path.to_s).to eq('/usr/bin/dpkg-deb')
        end
      end
    end
  end

  describe 'dev' do
    describe 'checkmake' do
      describe 'version' do
        it 'returns 8915bd4 by default' do
          expect(config.dev.checkmake.version).to eq('8915bd4')
        end
      end
    end
  end

  describe 'redis' do
    describe 'databases' do
      describe 'development' do
        describe 'rate_limiting' do
          it 'is 4 by default' do
            expect(config.redis.databases.development.rate_limiting).to eq(4)
          end
        end

        describe 'sessions' do
          it 'is 5 by default' do
            expect(config.redis.databases.development.sessions).to eq(5)
          end
        end

        describe 'repository_cache' do
          it 'is 2 by default' do
            expect(config.redis.databases.development.repository_cache).to eq(2)
          end
        end
      end

      describe 'test' do
        describe 'rate_limiting' do
          it 'is 14 by default' do
            expect(config.redis.databases.test.rate_limiting).to eq(14)
          end
        end

        describe 'sessions' do
          it 'is 15 by default' do
            expect(config.redis.databases.test.sessions).to eq(15)
          end
        end

        describe 'repository_cache' do
          it 'is 12 by default' do
            expect(config.redis.databases.test.repository_cache).to eq(12)
          end
        end
      end
    end

    describe '#dir' do
      it 'returns the redis directory' do
        expect(config.redis.dir).to eq(Pathname.new('/home/git/kdk/redis'))
      end
    end
  end

  describe 'snowplow_micro' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.snowplow_micro.enabled).to be(false)
      end
    end

    describe '#port' do
      it 'defaults to 9091' do
        expect(config.snowplow_micro.port).to eq(9091)
      end
    end

    describe '#image' do
      it 'defaults to snowplow/snowplow-micro:latest' do
        expect(config.snowplow_micro.image).to eq('snowplow/snowplow-micro:latest')
      end
    end
  end

  describe 'khulnasoft_shell' do
    context 'lfs' do
      describe '#pure_ssh_protocol_enabled' do
        it 'defaults to false' do
          expect(config.khulnasoft_shell.lfs.pure_ssh_protocol_enabled).to be(false)
        end
      end
    end

    context 'pat' do
      it 'sets default values for pat' do
        expect(config.khulnasoft_shell.pat.enabled).to be(true)
        expect(config.khulnasoft_shell.pat.allowed_scopes).to eq([])
      end
    end
  end

  describe 'khulnasoft_ai_gateway' do
    describe '#enabled' do
      it 'defaults to false' do
        expect(config.khulnasoft_ai_gateway.enabled).to be(false)
      end
    end

    describe '#__listen' do
      it "is 'http://kdk.example.com:5052'" do
        expect(config.khulnasoft_ai_gateway.__listen.to_s).to eq('http://kdk.example.com:5052')
      end
    end

    describe '#__service_command' do
      it "is 'support/exec-cd gitlab-ai-gateway poetry run ai_gateway'" do
        expect(config.khulnasoft_ai_gateway.__service_command).to eq('support/exec-cd gitlab-ai-gateway poetry run ai_gateway')
      end
    end
  end

  describe 'khulnasoft_http_router' do
    describe '#enabled' do
      it 'defaults to true' do
        expect(config.khulnasoft_http_router.enabled).to be(true)
      end
    end

    describe '#uses_different_port' do
      it 'defaults to false' do
        expect(config.khulnasoft_http_router.use_distinct_port?).to be(false)
      end
    end

    describe '#khulnasoft_rules_config' do
      it 'defaults to `session_prefix`' do
        expect(config.khulnasoft_http_router.khulnasoft_rules_config).to eq('session_prefix')
      end
    end

    describe '#port' do
      it 'defaults to 9393' do
        expect(config.khulnasoft_http_router.port).to eq(9393)
      end
    end
  end

  describe 'khulnasoft_topology_service' do
    describe '#enabled' do
      it 'defaults to true' do
        expect(config.khulnasoft_topology_service.enabled).to be(true)
      end
    end

    describe '#grpc_port' do
      it 'defaults to 9095' do
        expect(config.khulnasoft_topology_service.grpc_port).to eq(9095)
      end
    end

    describe '#rest_port' do
      it 'defaults to 9096' do
        expect(config.khulnasoft_topology_service.rest_port).to eq(9096)
      end
    end

    describe 'certificate files' do
      let(:certs_directory) { "/home/git/kdk/khulnasoft-topology-service/tmp/certs" }

      it 'they default to the certificate files in the temp directory' do
        expect(config.gitlab.topology_service.ca_file).to eq(Pathname.new(File.join(certs_directory, "ca-cert.pem")))
        expect(config.gitlab.topology_service.certificate_file).to eq(Pathname.new(File.join(certs_directory, "client-cert.pem")))
        expect(config.gitlab.topology_service.private_key_file).to eq(Pathname.new(File.join(certs_directory, "client-key.pem")))
      end
    end
  end

  describe 'openbao' do
    describe '#enabled' do
      it 'is disabled by default' do
        expect(config.openbao.enabled).to be(false)
        expect(config.openbao.enabled?).to be(false)
        expect(config.openbao?).to be(false)
      end
    end

    describe '#bin' do
      subject(:path) { default_config.openbao.bin }

      it { is_expected.to eq(default_config.kdk_root.join('openbao', 'bin', 'bao')) }
    end

    describe '#__server_command' do
      it 'defaults to dev mode' do
        expect(config.openbao.__server_command).to eq("#{config.openbao.bin} server --config /home/git/kdk/openbao/config.hcl")
      end
    end

    describe '#__listen' do
      it 'defaults to kdk hostname on port 8200' do
        expect(config.openbao.__listen).to eq("#{config.hostname}:8200")
      end
    end

    describe '#port' do
      it 'defaults to 8200' do
        expect(config.openbao.port).to eq(8200)
      end
    end
  end

  describe 'openbao-proxy' do
    describe '#enabled' do
      it 'is disabled by default' do
        expect(config.openbao.vault_proxy.enabled).to be(false)
        expect(config.openbao.vault_proxy.enabled?).to be(false)
        expect(config.openbao.vault_proxy?).to be(false)
      end
    end

    describe '#__server_command' do
      it 'defaults to dev mode' do
        expect(config.openbao.vault_proxy.__server_command).to eq("#{config.openbao.vault_proxy.bin} proxy --config /home/git/kdk/openbao/proxy_config.hcl")
      end
    end

    describe '#__listen' do
      it 'defaults to kdk hostname on port 8100' do
        expect(config.openbao.vault_proxy.__listen).to eq("#{config.hostname}:8100")
      end
    end

    describe '#port' do
      it 'defaults to 8100' do
        expect(config.openbao.vault_proxy.port).to eq(8100)
      end
    end
  end

  def create_dummy_executable(name)
    path = File.join(tmp_path, name)
    FileUtils.touch(path)
    File.chmod(0o755, path)

    path
  end
end
