# frozen_string_literal: true

require 'kdk/postgresql_upgrader'

RSpec.describe KDK::PostgresqlUpgrader do
  include ShelloutHelper

  let(:target_version) { 16 }

  subject { described_class.new(target_version) }

  describe '#initialize' do
    it 'initializes with a target version' do
      expect(subject.instance_variable_get(:@target_version)).to eq(target_version)
    end
  end

  describe '#upgrade!' do
    before do
      allow(subject).to receive_messages(
        upgrade_needed?: true,
        current_version: 14,
        kdk_stop: true,
        init_db_in_target_path: true,
        rename_current_data_dir: true,
        pg_upgrade: true,
        promote_new_db: true,
        kdk_reconfigure: true,
        pg_replica_upgrade: true,
        rename_current_data_dir_back: true
      )
    end

    context 'with asdf' do
      let(:result) { "  13.12\n  13.9\n  14.8\n  14.9\n  15.1\n  15.2\n  15.3\n 16.1\n 16.8\n" }
      let(:version_list_double) { kdk_shellout_double(try_run: result) }

      before do
        allow(KDK::Dependencies).to receive_messages(asdf_available?: true, asdf_available_versions: [13, 14, 15])

        shellout_double = kdk_shellout_double(try_run: '', exit_code: 0)

        allow_kdk_shellout_command(anything).and_return(shellout_double)
        allow_kdk_shellout_command(%w[asdf list postgres]).and_return(version_list_double)
      end

      describe '#bin_path' do
        it 'returns latest version' do
          stub_env('ASDF_DATA_DIR', '/home/on/the/range/.asdf')

          expect(subject.bin_path).to eq('/home/on/the/range/.asdf/installs/postgres/16.8/bin')
        end
      end

      describe '#bin_path_or_fallback' do
        it 'returns latest version' do
          stub_env('ASDF_DATA_DIR', '/home/on/the/range/.asdf')

          expect(subject.bin_path_or_fallback).to eq('/home/on/the/range/.asdf/installs/postgres/16.8/bin')
        end

        context 'when asdf fails' do
          before do
            shellout_err = kdk_shellout_double(try_run: 'something went wrong', exit_code: 1)
            allow_kdk_shellout_command(%w[asdf list postgres]).and_return(shellout_err)

            shellout_pg = kdk_shellout_double(run: '/home/on/the/range/.local/share/mise/installs/postgres/16.8/bin', exit_code: 0)
            allow_kdk_shellout_command(%w[pg_config --bindir], chdir: KDK.root).and_return(shellout_pg)
          end

          it 'returns the output of `pg_config --bindir`' do
            expect(subject.bin_path_or_fallback).to eq('/home/on/the/range/.local/share/mise/installs/postgres/16.8/bin')
          end
        end
      end

      context 'when upgrade is needed' do
        it 'performs a successful upgrade' do
          expect { subject.upgrade! }.to output(/Upgraded/).to_stdout
        end
      end

      context 'when upgrade is not needed' do
        before do
          allow(subject).to receive(:upgrade_needed?).and_return(false)
        end

        it 'does not perform an upgrade' do
          expect { subject.upgrade! }.to output(/already compatible/).to_stdout
        end
      end
    end
  end
end
