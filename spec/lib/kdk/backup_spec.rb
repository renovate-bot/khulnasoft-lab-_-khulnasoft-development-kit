# frozen_string_literal: true

RSpec.describe KDK::Backup do
  let(:kdk_root_dir) { '/home/git/kdk' }
  let(:kdk_root_path) { Pathname.new(kdk_root_dir) }

  let(:backups_path_only) { '.backups' }
  let(:backups_path) { kdk_root_path.join('.backups') }

  let!(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }

  before do
    allow(KDK).to receive(:root).and_return(kdk_root_path)
  end

  describe 'initialize' do
    context 'when the source file is outside of the KDK' do
      it 'raises an exception' do
        expect { described_class.new(Tempfile.new.path) }.to raise_error(KDK::Backup::SourceFileOutsideOfGdk)
      end
    end

    context 'when the source file does not exist' do
      it 'raises an exception' do
        fake_source_file = kdk_root_path.join('tmp/filethatdoesntexist.txt')

        expect { described_class.new(fake_source_file) }.to raise_error(KDK::Backup::SourceFileDoesntExist)
      end
    end

    context 'when the source file does exist' do
      it 'does not raise an exception' do
        fake_source_file = kdk_root_path.join('Procfile')
        stub_source_file(fake_source_file)

        expect(described_class.new(fake_source_file)).to be_instance_of(described_class)
      end
    end
  end

  describe '.backup_root' do
    it 'is /Users/ash/src/gitlab/khulnasoft-development-kit/.backups' do
      fake_root_pathname = stub_backup_root

      expect(described_class.backup_root).to be(fake_root_pathname)
    end
  end

  describe '#source_file' do
    it 'returns a fully qualified Pathname to the backup source file' do
      fake_source_file = kdk_root_path.join('Procfile')
      stub_source_file(fake_source_file)

      stub_backup_root

      expect(described_class.new(fake_source_file).source_file.to_s).to eq(fake_source_file.to_s)
    end
  end

  describe '#destination_file' do
    it 'returns a fully qualified Pathname to the backup destination file' do
      fake_source_file = kdk_root_path.join('Procfile')
      stub_source_file(fake_source_file)

      stub_backup_root

      travel_to(now) do
        fake_destination_file = backups_path.join('Procfile.20210506185031')

        expect(described_class.new(fake_source_file).destination_file.to_s).to eq(fake_destination_file.to_s)
      end
    end
  end

  describe '#relative_source_file' do
    it 'returns a relative Pathname to the backup source file' do
      fake_source_file_only = 'Procfile'
      fake_source_file = kdk_root_path.join(fake_source_file_only)
      stub_source_file(fake_source_file)

      stub_backup_root

      expect(described_class.new(fake_source_file).relative_source_file.to_s).to eq(fake_source_file_only)
    end
  end

  describe '#recover_cmd_string' do
    it 'returns the cp command that recovers a backed up file' do
      fake_source_file = kdk_root_path.join('Procfile')
      stub_source_file(fake_source_file)

      stub_backup_root

      travel_to(now) do
        fake_destination_file = File.join(backups_path, 'Procfile.20210506185031')

        expect(described_class.new(fake_source_file).recover_cmd_string).to eq("cp -f '#{fake_destination_file}' \\\n'#{fake_source_file}'\n")
      end
    end
  end

  describe '#backup!' do
    shared_examples 'a file to be backed up' do |fake_source_file, fake_destination_file, advise|
      it 'and makes a backup' do
        fake_source_file_full = kdk_root_path.join(fake_source_file)
        stub_source_file(fake_source_file_full)

        fake_root_pathname = stub_backup_root

        allow(fake_root_pathname).to receive(:mkpath).and_return(true)

        travel_to(now) do
          fake_destination_file_full = File.join(kdk_root_dir, fake_destination_file)

          backup_params = [fake_source_file_full.to_s, fake_destination_file_full.to_s]
          expect(FileUtils).to receive(:mv).with(*backup_params).and_return(true)

          advise_message = "A backup of '#{fake_source_file}' has been made at '#{fake_destination_file}'."
          if advise
            expect(KDK::Output).to receive(:info).with(advise_message)
          else
            expect(KDK::Output).not_to receive(:info).with(advise_message)
          end

          expect(described_class.new(fake_source_file_full).backup!(advise: advise)).to be(true)
        end
      end
    end

    context 'is a file only' do
      it_behaves_like 'a file to be backed up', 'Procfile', '.backups/Procfile.20210506185031', true
      it_behaves_like 'a file to be backed up', 'Procfile', '.backups/Procfile.20210506185031', false
    end

    context 'is a file within a directory' do
      it_behaves_like 'a file to be backed up', 'gitlab/config/gitlab.yml', '.backups/khulnasoft__config__gitlab.yml.20210506185031', true
      it_behaves_like 'a file to be backed up', 'gitlab/config/gitlab.yml', '.backups/khulnasoft__config__gitlab.yml.20210506185031', false
    end
  end

  describe '#restore!' do
    let(:backup) { described_class.new(source_file) }
    let(:source_file) { kdk_root_path.join('kdk.yml') }

    before do
      stub_source_file(source_file)
      stub_backup_root
    end

    context 'with existing backup' do
      let(:backup_file) { backup.destination_file }

      it 'restores a backup' do
        travel_to(now) do
          allow(backup_file).to receive(:exist?).and_return(true)
          expect(FileUtils).to receive(:cp).with(backup_file.to_s, source_file.to_s)
          expect(KDK::Output).to receive(:info)
            .with("Backup '.backups/kdk.yml.20210506185031' has been restored to 'kdk.yml'.")

          expect(backup.restore!).to be(true)
        end
      end

      it 'restores a backup silently' do
        travel_to(now) do
          allow(backup_file).to receive(:exist?).and_return(true)
          expect(FileUtils).to receive(:cp).with(backup_file.to_s, source_file.to_s)
          expect(KDK::Output).not_to receive(:info)

          expect(backup.restore!(advise: false)).to be(true)
        end
      end
    end

    context 'without existing backup' do
      it 'does not restore anything' do
        expect(KDK::Output).not_to receive(:info)
        expect(backup.restore!).to be(false)
      end
    end
  end

  def stub_backup_root
    fake_root_pathname = Pathname.new(kdk_root_dir).join(backups_path_only)

    allow(kdk_root_path).to receive(:join).with('.backups').and_return(fake_root_pathname)
    allow(fake_root_pathname).to receive(:realpath).and_return(fake_root_pathname)

    fake_root_pathname
  end

  def stub_source_file(file)
    file = file.to_s
    fake_source_file_pathname = Pathname.new(file)

    allow(Pathname).to receive(:new).and_call_original
    allow(Pathname).to receive(:new).with(file).and_return(fake_source_file_pathname)
    allow(fake_source_file_pathname).to receive_messages(expand_path: fake_source_file_pathname, exist?: true)

    fake_source_file_pathname
  end
end
