# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Registry do
  include ShelloutHelper

  let(:enabled) { true }
  let(:registry_build_bin_path) { '/home/git/kdk/container-registry/bin/registry' }

  before do
    allow(KDK.config).to receive_message_chain(:registry, :enabled?).and_return(enabled)
    allow(KDK.config).to receive_message_chain(:registry, :__registry_build_bin_path).and_return(registry_build_bin_path)
  end

  describe '#success?' do
    context 'when registry is disabled' do
      let(:enabled) { false }

      it 'returns true' do
        expect(subject).to be_success
      end
    end

    context 'when registry is enabled' do
      let(:enabled) { true }

      context 'focusing on checking DB migrations' do
        before do
          allow(subject).to receive(:dir_length_ok?).and_return(true)
        end

        context 'when there are DB migrations that need attention' do
          it 'returns false' do
            stub_unmigrated_migration

            expect(subject.success?).to be_falsey
          end
        end

        context 'when there are no DB migrations that need attention' do
          it 'returns true' do
            stub_migrated_migration

            expect(subject.success?).to be_truthy
          end
        end
      end
    end
  end

  describe '#detail' do
    context 'focusing on checking DB migrations' do
      before do
        allow(subject).to receive(:dir_length_ok?).and_return(true)
      end

      context 'when there are DB migrations that need attention' do
        it 'returns detail content' do
          stub_unmigrated_migration

          expect(subject.detail).to match(/The following registry DB migrations don't appear to have been applied/)
        end
      end

      context 'when there are no DB migrations that need attention' do
        it 'returns nil' do
          stub_migrated_migration

          expect(subject.detail).to be_nil
        end
      end
    end
  end

  def stub_unmigrated_migration
    stub_db_migrations('20240525173505_add_repositories_index', 'no')
  end

  def stub_migrated_migration
    stub_db_migrations('20240525173505_add_repositories_index', '2024-07-12 17:03:00.155292 +1000 AEST')
  end

  def stub_db_migrations(migration, status)
    line = "| #{migration} | #{status} |"

    command = "#{registry_build_bin_path} database migrate status /home/git/kdk/registry/config.yml"
    shellout_double = kdk_shellout_double(readlines: [line])
    allow_kdk_shellout_command(command).and_return(shellout_double)
  end
end
