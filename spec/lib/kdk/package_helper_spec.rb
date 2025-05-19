# frozen_string_literal: true

require_relative '../../../lib/kdk/package_config'

RSpec.describe KDK::PackageHelper do
  let(:package) { :test_package }
  let(:package_version) { '1.0.0' }
  let(:package_config) do
    {
      package_name: 'test_package',
      project_path: '/path/to/project',
      upload_path: '/path/to/upload',
      download_paths: ['/path/to/download'],
      platform_specific: platform_specific
    }
  end

  let(:package_helper) { described_class.new(package: package, token: 'test_token') }

  let(:platform) { 'linux' }
  let(:architecture) { 'amd64' }

  before do
    allow(KDK::VersionManager).to receive(:fetch).with(:test_package).and_return(package_version)

    stub_const('KDK::PackageConfig::PROJECTS', { test_package: package_config })
    allow(KDK::Machine).to receive_messages(platform: platform, architecture: architecture)
  end

  describe '#initialize' do
    let(:platform_specific) { false }

    context 'when project_id is not provided' do
      it 'uses the default KDK_PROJECT_ID' do
        expect(package_helper.project_id).to eq(KDK::PackageHelper::KDK_PROJECT_ID)
      end
    end

    context 'when project_id is provided' do
      let(:package_helper) { described_class.new(package: package, project_id: '12345', token: 'test_token') }

      it 'sets instance variables correctly' do
        expect(package_helper.package_name).to eq('test_package')
        expect(package_helper.package_path).to eq('test_package.tar.gz')
        expect(package_helper.package_version).to eq('1.0.0')
        expect(package_helper.project_path).to eq(Pathname.new('/path/to/project'))
        expect(package_helper.upload_path).to eq(Pathname.new('/path/to/upload'))
        expect(package_helper.download_paths).to eq([Pathname.new('/path/to/download')])
        expect(package_helper.platform_specific).to be(false)
        expect(package_helper.project_id).to eq('12345')
        expect(package_helper.token).to eq('test_token')
      end
    end
  end

  describe '#create_package' do
    let(:platform_specific) { false }
    let(:directory) { instance_double(Pathname, directory?: true, to_s: 'test_directory', stat: instance_double(File::Stat, mode: 0o755)) }
    let(:first_file) { instance_double(Pathname, directory?: false) }
    let(:second_file) { instance_double(Pathname, directory?: false) }
    let(:tar_double) { instance_double(Gem::Package::TarWriter) }

    it 'creates a package' do
      allow(File).to receive(:open).with('test_package.tar.gz', 'wb').and_yield(instance_double(File))
      allow(Zlib::GzipWriter).to receive(:wrap).and_yield(instance_double(Zlib::GzipWriter))
      allow(Gem::Package::TarWriter).to receive(:new).and_yield(tar_double)
      allow(package_helper.upload_path).to receive(:find).and_yield(directory).and_yield(first_file).and_yield(second_file)

      expect(tar_double).to receive(:mkdir).with('test_directory', any_args)
      expect(package_helper).to receive(:add_file_to_tar).twice
      expect(KDK::Output).to receive(:success).with(include('Package created at'))

      package_helper.create_package
    end

    it 'raises an error when an unexpected error occurs' do
      allow(File).to receive(:open).with('test_package.tar.gz', 'wb').and_raise(StandardError, 'Error message')

      expect { package_helper.create_package }.to raise_error(StandardError, /Package creation failed: Error message/)
    end
  end

  describe '#upload_package' do
    let(:platform_specific) { false }
    let(:request) { instance_double(Net::HTTP::Put) }
    let(:http) { instance_double(Net::HTTP) }
    let(:response) { instance_double(Net::HTTPSuccess, is_a?: true) }
    let(:stubbed_env) { nil }
    let(:package_versions) { %w[1.0.0 latest] }
    let(:package_name) { "test_package" }
    let(:base_uri) { "https://khulnasoft.com/api/v4/projects/74823/packages/generic/#{package_name}" }
    let(:versioned_uri) { URI.parse("#{base_uri}/1.0.0/test_package.tar.gz") }
    let(:latest_uri) { URI.parse("#{base_uri}/latest/test_package.tar.gz") }

    before do
      stub_const('ENV', stubbed_env) if stubbed_env

      [versioned_uri, latest_uri].each do |uri|
        allow(Net::HTTP::Put).to receive(:new).with(uri).and_return(request)
      end

      allow(request).to receive(:[]=).with('JOB-TOKEN', 'test_token')
      allow(request).to receive(:body=).with('package content')
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with('test_package.tar.gz').and_return('package content')
      allow(http).to receive(:request).and_return(response)
      allow(Net::HTTP).to receive(:start).and_yield(http).and_return(response)
      allow(package_helper).to receive(:create_package)
    end

    shared_examples 'uploads packages successfully' do
      it 'uploads both the versioned and latest packages' do
        expect(package_helper).to receive(:create_package)
        expect(request).to receive(:[]=).with('JOB-TOKEN', 'test_token').twice
        expect(request).to receive(:body=).with('package content').twice
        expect(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true).twice
        expect(KDK::Output).to receive(:success).with(include('Package uploaded successfully')).twice

        package_helper.upload_package
      end
    end

    context 'when uploading both versioned and latest packages' do
      include_examples 'uploads packages successfully'
    end

    it 'raises an error when create_package fails' do
      allow(package_helper).to receive(:create_package).and_raise(StandardError, /Package creation failed: Error message/)

      expect { package_helper.upload_package }.to raise_error(StandardError, /Package creation failed: Error message/)
    end

    it 'raises an error when upload fails' do
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      allow(response).to receive(:body).and_return('Error message')

      expect(package_helper).to receive(:create_package)
      expect { package_helper.upload_package }.to raise_error(RuntimeError, /Upload failed for version '1.0.0': Error message/)
    end

    context 'when platform_specific is true' do
      let(:platform_specific) { true }
      let(:package_name) { "test_package-linux-amd64" }
      let(:base_uri) { "https://khulnasoft.com/api/v4/projects/74823/packages/generic/#{package_name}" }
      let(:versioned_uri) { URI.parse("#{base_uri}/1.0.0/test_package.tar.gz") }
      let(:latest_uri) { URI.parse("#{base_uri}/latest/test_package.tar.gz") }

      before do
        [versioned_uri, latest_uri].each do |uri|
          allow(Net::HTTP::Put).to receive(:new).with(uri).and_return(request)
        end
      end

      context 'and OS and architecture are supported' do
        include_examples 'uploads packages successfully'
      end

      context 'when BUILD_ARCH is set to arm64' do
        let(:stubbed_env) { { 'BUILD_ARCH' => 'arm64' } }
        let(:package_name) { "test_package-linux-arm64" }
        let(:base_uri) { "https://khulnasoft.com/api/v4/projects/74823/packages/generic/#{package_name}" }
        let(:versioned_uri) { URI.parse("#{base_uri}/1.0.0/test_package.tar.gz") }
        let(:latest_uri) { URI.parse("#{base_uri}/latest/test_package.tar.gz") }

        before do
          [versioned_uri, latest_uri].each do |uri|
            allow(Net::HTTP::Put).to receive(:new).with(uri).and_return(request)
          end
        end

        include_examples 'uploads packages successfully'
      end
    end
  end

  describe '#download_package' do
    let(:base_uri) { "https://khulnasoft.com/api/v4/projects/74823/packages/generic/#{expected_package_name}" }
    let(:versioned_uri) { URI.parse("#{base_uri}/1.0.0/test_package.tar.gz") }
    let(:latest_uri) { URI.parse("#{base_uri}/latest/test_package.tar.gz") }
    let(:response) { instance_double(Net::HTTPSuccess) }
    let(:current_sha) { 'abc123' }
    let(:stored_sha) { 'def456' }
    let(:fixture_path) { File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'package.tar.gz') }
    let(:content) { File.read(fixture_path) }
    let(:tmpdir) { Dir.mktmpdir }

    before do
      package_config[:download_paths] = [tmpdir]
      allow(package_helper).to receive(:sha_file_root).and_return(File.join(tmpdir, 'sha_file_root'))
      allow(package_helper).to receive_messages(current_commit_sha: current_sha, stored_commit_sha: stored_sha)
      allow(File).to receive(:write).and_call_original
      allow(File).to receive(:write).with('test_package.tar.gz', content)
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with('test_package.tar.gz', 'rb').and_yield(StringIO.new(content))
    end

    shared_examples 'downloads the package successfully' do
      before do
        stub_request(:get, versioned_uri.to_s).to_return(body: content)
      end

      it 'downloads the package' do
        expect(KDK::Output).to receive(:info).with(include('Downloading package from'))
        expect(KDK::Output).to receive(:success).with(include('Package downloaded successfully'))
        expect(KDK::Output).to receive(:success).with(include('Package extracted successfully'))

        package_helper.download_package

        expect(Dir.children(tmpdir)).to match_array(%w[hello-world.sh sha_file_root])
        sha_file_path = File.join(tmpdir, 'sha_file_root', '.cache')
        expect(Dir.children(sha_file_path)).to eq([expected_commit_sha_name])
        expect(File.read(File.join(sha_file_path, expected_commit_sha_name))).to eq(current_sha)
      end
    end

    context 'when platform_specific is true' do
      let(:platform_specific) { true }

      context 'and OS and architecture are supported' do
        include_examples 'downloads the package successfully'
      end

      context 'and OS and architecture are not supported' do
        let(:platform) { 'unsupported_os' }
        let(:architecture) { 'unsupported_arch' }

        it 'does not download the package' do
          expect(KDK::Output).to receive(:info).with(include('Unsupported OS or architecture detected'))
          expect(Net::HTTP).not_to receive(:get_response).with(versioned_uri)

          package_helper.download_package
        end
      end
    end

    context 'when platform_specific is false' do
      let(:platform_specific) { false }
      let(:platform) { 'unsupported_os' }
      let(:architecture) { 'unsupported_arch' }

      include_examples 'downloads the package successfully'
    end

    context 'when current commit SHA is different from stored SHA' do
      let(:platform_specific) { false }

      include_examples 'downloads the package successfully'
    end

    context 'when current commit SHA matches stored SHA' do
      let(:platform_specific) { false }
      let(:current_sha) { stored_sha }

      it 'does not download the package' do
        expect(KDK::Output).to receive(:success).with(include('No changes detected'))
        expect(Net::HTTP).not_to receive(:get_response)
        expect(package_helper).not_to receive(:extract_package)
        expect(File).not_to receive(:write)

        package_helper.download_package
      end
    end

    context 'when download fails' do
      let(:platform_specific) { false }

      before do
        stub_request(:get, versioned_uri.to_s).to_return(status: 502, body: 'Error message')
      end

      it 'raises an error' do
        expect(KDK::Output).to receive(:info).with(include('Downloading package from'))
        expect { package_helper.download_package }.to raise_error(RuntimeError, /Download failed: Error message/)
      end
    end

    context 'when extract_package fails', :hide_output do
      let(:platform_specific) { false }

      before do
        stub_request(:get, versioned_uri.to_s).to_return(body: content)
      end

      it 'raises an error' do
        allow(package_helper).to receive(:extract_package).and_raise(StandardError, 'Error message')

        expect { package_helper.download_package }.to raise_error(StandardError, /Error message/)
      end
    end

    context 'when requested version is not found but the latest version is available', :hide_output do
      let(:platform_specific) { false }

      before do
        stub_request(:get, versioned_uri.to_s).to_return(status: 404, body: 'not found')
        stub_request(:get, latest_uri.to_s).to_return(body: content)
      end

      it 'downloads the latest package successfully' do
        package_helper.download_package

        expect(Dir.children(tmpdir)).to match_array(%w[hello-world.sh sha_file_root])
      end
    end

    context 'when both version and latest downloads fail', :hide_output do
      let(:platform_specific) { false }

      before do
        stub_request(:get, versioned_uri.to_s).to_return(status: 404, body: 'not here')
        stub_request(:get, latest_uri.to_s).to_return(status: 500, body: 'server error')
      end

      it 'raises an error' do
        expect { package_helper.download_package }.to raise_error(RuntimeError, /server/)
      end
    end
  end

  def stub_tar_reader
    tar_reader = instance_double(Gem::Package::TarReader)
    allow(Gem::Package::TarReader).to receive(:new).and_yield(tar_reader)
    allow(tar_reader).to receive(:each).and_yield(instance_double(Gem::Package::TarReader::Entry, full_name: 'fake/path/to/file'))
  end

  def expected_package_name
    platform_specific ? 'test_package-linux-amd64' : 'test_package'
  end

  def expected_commit_sha_name
    platform_specific ? '.test_package_linux_amd64_commit_sha' : '.test_package_commit_sha'
  end
end
