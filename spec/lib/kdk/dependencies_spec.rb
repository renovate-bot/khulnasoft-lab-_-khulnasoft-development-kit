# frozen_string_literal: true

RSpec.describe KDK::Dependencies do
  let(:tmp_path) { Dir.mktmpdir('kdk-path') }
  let(:asdf_path) { Pathname(tmp_path).join('.asdf') }

  before do
    unstub_find_executable
    stub_env('PATH', tmp_path)
  end

  describe '.homebrew_available?' do
    it 'returns true when Homebrew is available in PATH' do
      create_dummy_executable('brew')

      expect(described_class.homebrew_available?).to be_truthy
    end

    it 'returns false when Homebrew is not available in PATH' do
      expect(described_class.homebrew_available?).to be_falsey
    end
  end

  describe '.macports_available?' do
    it 'returns true when Macports is available in PATH' do
      create_dummy_executable('port')

      expect(described_class.macports_available?).to be_truthy
    end

    it 'returns false when Macports is not available in PATH' do
      expect(described_class.macports_available?).to be_falsey
    end
  end

  describe '.linux_apt_available?' do
    it 'returns true when APT is available in PATH' do
      create_dummy_executable('apt')

      expect(described_class.linux_apt_available?).to be_truthy
    end

    it 'returns false when APT is not available in PATH' do
      expect(described_class.linux_apt_available?).to be_falsey
    end
  end

  describe '.asdf_available?' do
    subject { described_class.asdf_available? }

    it 'returns true when ASDF_DATA_DIR is present' do
      stub_env('ASDF_DIR', nil)
      stub_env('ASDF_DATA_DIR', asdf_path)

      expect(subject).to be_truthy
    end

    it 'returns true when ASDF_DIR is present' do
      stub_env('ASDF_DIR', asdf_path)
      stub_env('ASDF_DATA_DIR', nil)

      expect(subject).to be_truthy
    end

    it 'returns true when asdf binary is available in PATH' do
      create_dummy_executable('asdf')

      stub_env('ASDF_DIR', nil)
      stub_env('ASDF_DATA_DIR', nil)

      expect(subject).to be_truthy
    end

    it 'returns true when both asdf binary and ENV variables are present' do
      create_dummy_executable('asdf')
      stub_env('ASDF_DIR', asdf_path)
      stub_env('ASDF_DATA_DIR', asdf_path)

      expect(subject).to be_truthy
    end

    it 'returns false when neither asdf binary not ENV variables are present' do
      stub_env('ASDF_DIR', nil)
      stub_env('ASDF_DATA_DIR', nil)

      expect(subject).to be_falsey
    end

    it 'returns false when the user opted out' do
      stub_kdk_yaml('asdf' => { 'opt_out' => true })
      create_dummy_executable('asdf')
      stub_env('ASDF_DIR', asdf_path)

      expect(subject).to be_falsey
    end
  end

  describe '.mise_available?' do
    subject { described_class.mise_available? }

    it 'returns true when it is enabled and installed' do
      stub_kdk_yaml('mise' => { 'enabled' => true })
      create_dummy_executable('mise')

      expect(subject).to be_truthy
    end

    it 'returns false when it is enabled but not installed' do
      stub_kdk_yaml('mise' => { 'enabled' => true })

      expect(subject).to be_falsey
    end

    it 'returns false when it is not enabled' do
      stub_kdk_yaml('mise' => { 'enabled' => false })
      create_dummy_executable('mise')

      expect(subject).to be_falsey
    end
  end
end
