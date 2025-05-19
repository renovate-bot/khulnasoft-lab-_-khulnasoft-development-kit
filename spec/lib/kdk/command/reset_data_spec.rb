# frozen_string_literal: true

RSpec.describe KDK::Command::ResetData do
  include ShelloutHelper

  let!(:root) { KDK.root }
  let!(:backup_base_dir) { root.join('.backups') }

  context 'prompt behavior' do
    let(:prompt_response) { nil }

    before do
      allow(KDK::Output).to receive(:warn).with("We're about to remove _all_ (KhulnaSoft and praefect) PostgreSQL data, Rails uploads and git repository data.")
      allow(KDK::Output).to receive(:warn).with("Backups will be made in '#{backup_base_dir}', just in case!")
      allow(KDK::Output).to receive(:interactive?).and_return(true)
      allow(KDK::Output).to receive(:prompt).with('Are you sure? [y/N]').and_return(prompt_response)
    end

    context 'when the user does not accept / aborts the prompt' do
      let(:prompt_response) { 'no' }

      it 'does not run' do
        expect(subject).not_to receive(:stop_and_backup!)
        expect(subject).not_to receive(:reset_data!)

        subject.run
      end
    end

    context 'when the user accepts the prompt' do
      let(:prompt_response) { 'yes' }

      it 'runs' do
        expect(subject).to receive(:stop_and_backup!).and_return(true)
        expect(subject).to receive(:reset_data!).and_return(true)

        subject.run
      end
    end
  end

  context 'backup behavior' do
    let!(:now) { Time.now }
    let!(:current_timestamp) { now.strftime('%Y-%m-%d_%H.%M.%S') }
    let!(:postgresql_data_directory) { root.join('postgresql', 'data') }
    let!(:backup_postgresql_data_directory) { backup_base_dir.join('postgresql', "data.#{current_timestamp}") }
    let!(:redis_dump_rdb_path) { root.join('redis', 'dump.rdb') }
    let!(:backup_redis_dump_rdb_path) { backup_base_dir.join('redis', "dump.rdb.#{current_timestamp}") }

    before do
      allow(Runit).to receive(:stop).with(quiet: true)
      allow(KDK).to receive(:root).and_return(root)
      allow(subject).to receive(:continue?).and_return(true)
    end

    context 'when backup data script fails' do
      it 'errors out', :hide_stdout do
        travel_to(now) do
          stub_postgres_data_move
          allow(FileUtils).to receive(:mv).with(postgresql_data_directory, backup_postgresql_data_directory).and_raise(Errno::ENOENT)

          expect(KDK::Output).to receive(:error).with("Failed to rename path '#{postgresql_data_directory}' to '#{backup_postgresql_data_directory}/' - No such file or directory", Errno::ENOENT)
          expect(KDK::Output).to receive(:error).with('Failed to backup data.')
          expect(subject).to receive(:display_help_message)
          expect(KDK).not_to receive(:make)

          subject.run
        end
      end
    end

    context 'when backup data script succeeds', :hide_stdout do
      let!(:rails_uploads_directory) { root.join('khulnasoft', 'public', 'uploads') }
      let!(:backup_rails_uploads_directory) { backup_base_dir.join('khulnasoft', 'public', "uploads.#{current_timestamp}") }
      let!(:git_repositories_data_directory) { root.join('repositories') }
      let!(:backup_git_repositories_data_directory) { backup_base_dir.join("repositories.#{current_timestamp}") }
      let!(:git_repository_storages_data_directory) { root.join('repository_storages') }
      let!(:backup_git_repository_storages_data_directory) { backup_base_dir.join("repository_storages.#{current_timestamp}") }

      context 'but make command fails' do
        it 'errors out' do
          travel_to(now) do
            stub_data_moves

            sh = kdk_shellout_double(success?: false, stderr_str: 'Error')
            expect(KDK).to receive(:make).with('khulnasoft-topology-service-setup', 'ensure-databases-setup', 'reconfigure').and_return(sh)

            expect(KDK::Output).to receive(:error).with('Failed to reset data.', 'Error')
            expect(KDK::Command::Start).not_to receive(:new)
            expect(subject).to receive(:display_help_message)

            subject.run
          end
        end
      end

      context 'and make command succeeds also' do
        it 'resets data' do
          travel_to(now) do
            stub_data_moves

            sh = kdk_shellout_double(success?: true)
            expect(KDK).to receive(:make).with('khulnasoft-topology-service-setup', 'ensure-databases-setup', 'reconfigure').and_return(sh)

            expect(KDK::Output).to receive(:notice).with("Moving PostgreSQL data from '#{postgresql_data_directory}' to '#{backup_postgresql_data_directory}/'")
            expect(KDK::Output).to receive(:notice).with("Moving redis dump.rdb from '#{redis_dump_rdb_path}' to '#{backup_redis_dump_rdb_path}/'")
            expect(KDK::Output).to receive(:notice).with("Moving Rails uploads from '#{rails_uploads_directory}' to '#{backup_rails_uploads_directory}/'")
            expect(KDK::Output).to receive(:notice).with("Moving git repository data from '#{git_repositories_data_directory}' to '#{backup_git_repositories_data_directory}/'")
            expect(KDK::Output).to receive(:notice).with("Moving more git repository data from '#{git_repository_storages_data_directory}' to '#{backup_git_repository_storages_data_directory}/'")
            expect(KDK::Output).to receive(:notice).with('Successfully reset data!')
            expect_any_instance_of(KDK::Command::Start).to receive(:run)

            subject.run
          end
        end
      end
    end

    def expect_rename_success(directory, new_directory)
      expect(FileUtils).to receive(:mv).with(directory, new_directory).and_return(true)
    end

    def allow_make_backup_base_dir(directory)
      directory_base_name = directory.dirname
      allow(FileUtils).to receive(:mkdir_p).with(directory_base_name).and_return([directory_base_name])
    end

    def stub_data_moves
      stub_postgres_data_move
      expect_rename_success(postgresql_data_directory, backup_postgresql_data_directory)

      stub_redis_dump_rdb_move
      expect_rename_success(redis_dump_rdb_path, backup_redis_dump_rdb_path)

      stub_rails_uploads_move
      expect_rename_success(rails_uploads_directory, backup_rails_uploads_directory)

      stub_git_repositories_data_move
      expect_rename_success(git_repositories_data_directory, backup_git_repositories_data_directory)

      stub_git_repository_storages_data_move
      expect_rename_success(git_repository_storages_data_directory, backup_git_repository_storages_data_directory)
    end

    def stub_postgres_data_move
      allow(root).to receive(:join).with('.backups', 'postgresql', "data.#{current_timestamp}").and_return(backup_postgresql_data_directory)
      allow(root).to receive(:join).with('postgresql', 'data').and_return(postgresql_data_directory)

      allow(postgresql_data_directory).to receive(:exist?).and_return(true)
      allow_make_backup_base_dir(backup_postgresql_data_directory)
    end

    def stub_redis_dump_rdb_move
      allow(root).to receive(:join).with('.backups', 'redis', "dump.rdb.#{current_timestamp}").and_return(backup_redis_dump_rdb_path)
      allow(root).to receive(:join).with('redis', 'dump.rdb').and_return(redis_dump_rdb_path)

      allow(redis_dump_rdb_path).to receive(:exist?).and_return(true)
      allow_make_backup_base_dir(backup_redis_dump_rdb_path)
    end

    def stub_rails_uploads_move
      allow(root).to receive(:join).with('.backups', 'khulnasoft', 'public', "uploads.#{current_timestamp}").and_return(backup_rails_uploads_directory)
      allow(root).to receive(:join).with('khulnasoft', 'public', 'uploads').and_return(rails_uploads_directory)

      allow(rails_uploads_directory).to receive(:exist?).and_return(true)
      allow_make_backup_base_dir(backup_rails_uploads_directory)
    end

    def stub_git_repositories_data_move
      allow(root).to receive(:join).with('.backups', "repositories.#{current_timestamp}").and_return(backup_git_repositories_data_directory)
      allow(root).to receive(:join).with('repositories').and_return(git_repositories_data_directory)

      allow_make_backup_base_dir(backup_git_repositories_data_directory)
      allow(git_repositories_data_directory).to receive(:exist?).and_return(true)

      shellout_double = kdk_shellout_double(try_run: '', success?: true)
      expect_kdk_shellout_command('git restore repositories', chdir: root).and_return(shellout_double)
    end

    def stub_git_repository_storages_data_move
      allow(root).to receive(:join).with('.backups', "repository_storages.#{current_timestamp}").and_return(backup_git_repository_storages_data_directory)
      allow(root).to receive(:join).with('repository_storages').and_return(git_repository_storages_data_directory)

      allow_make_backup_base_dir(backup_git_repository_storages_data_directory)
      allow(git_repository_storages_data_directory).to receive(:exist?).and_return(true)
    end
  end
end
