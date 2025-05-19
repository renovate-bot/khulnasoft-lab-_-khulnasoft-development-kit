# frozen_string_literal: true

RSpec.describe KDK::Command::Update do
  include ShelloutHelper

  let(:sh) { kdk_shellout_double(success?: true) }
  let(:kdk_available_after_update?) { true }

  before do
    allow(KDK::Hooks).to receive(:execute_hooks)
    allow(KDK).to receive(:make).and_return(sh)
    allow_kdk_shellout_command(%w[git rev-parse HEAD], chdir: KDK.config.kdk_root).and_return(
      kdk_shellout_double(success?: true, run: 'abcdef1234')
    )
    reconfigure_task = instance_double(Rake::Task, invoke: nil)
    allow(Rake::Task).to receive(:[]).with(:reconfigure).and_return(reconfigure_task)
    allow(Utils).to receive(:executable_exist_via_tooling_manager?).and_return(kdk_available_after_update?)

    kdk_migrate_task = instance_double(Rake::Task, invoke: nil)
    allow(Rake::Task).to receive(:[]).with('kdk:migrate').and_return(kdk_migrate_task)

    # Stubs for run_weekly_diagnostics
    allow_kdk_shellout_command('asdf').and_return(
      kdk_shellout_double(success?: true, readlines: [])
    )
    allow(KDK.config).to receive(:__cache_dir).and_return(Pathname.new('/fake/cache'))
    allow(FileUtils).to receive(:mkdir_p)
    allow(File).to receive(:exist?).and_return(false)
    allow(File).to receive(:write)
  end

  describe '#run', :hide_output do
    let(:env) { { 'PG_AUTO_UPDATE' => '1' } }

    context 'when self-update is enabled' do
      it 'runs self-update and update' do
        expect(KDK).to receive(:make).with('self-update')
        task = instance_double(Rake::Task, invoke: nil)
        expect(Rake::Task).to receive(:[]).with(:update).and_return(task)
        expect_any_instance_of(KDK::Announcements).to receive(:render_all)
        expect(KDK::Output).to receive(:success).with('Successfully updated!')

        subject.run
      end

      context 'when the sha was updated' do
        after do
          ENV['KDK_SELF_UPDATE'] = nil
        end

        it 'runs "kdk update" with the exec syscall' do
          expect(KDK).to receive(:make).with('self-update') do
            expect_kdk_shellout.with(%w[git rev-parse HEAD], chdir: KDK.config.kdk_root).and_return(
              kdk_shellout_double(success?: true, run: 'd06f00d')
            )
            sh
          end
          error = 'Kernel.exec stops and replaces the current process'
          expect(Kernel).to receive(:exec).with('kdk update').and_raise(error)
          expect(Dir).to receive(:chdir).with(KDK.config.kdk_root.to_s)

          expect { subject.run }.to raise_error(error)
          expect(ENV.fetch('KDK_SELF_UPDATE', nil)).to eq('0')
        end
      end
    end

    context 'when self-update is disabled' do
      before do
        stub_env('KDK_SELF_UPDATE', '0')
      end

      it 'only runs update' do
        expect(KDK).not_to receive(:make).with('self-update')
        task = instance_double(Rake::Task, invoke: nil)
        expect(Rake::Task).to receive(:[]).with(:update).and_return(task)
        expect(task).to receive(:invoke)
        expect_any_instance_of(KDK::Announcements).to receive(:render_all)
        expect(KDK::Output).to receive(:success).with('Successfully updated!')

        subject.run
      end
    end

    context 'when update fails' do
      it 'displays an error message', hide_output: false do
        stub_no_color_env('true')
        expect(KDK).to receive(:make).with('self-update')
        task = instance_double(Rake::Task)
        expect(Rake::Task).to receive(:[]).with(:update).and_return(task)
        expect(task).to receive(:invoke).and_raise('test error')
        expect_any_instance_of(KDK::Announcements).not_to receive(:render_all)

        expect { subject.run }
          .to output(/ERROR: test error\nERROR: Failed to update/).to_stderr
          .and output(/You can try the following that may be of assistance/).to_stdout
      end
    end

    context 'when migrate fails' do
      it 'displays an error message', hide_output: false do
        stub_no_color_env('true')
        expect(KDK).to receive(:make).with('self-update')

        migrate_task = instance_double(Rake::Task)
        expect(Rake::Task).to receive(:[]).with('kdk:migrate').and_return(migrate_task)
        expect(migrate_task).to receive(:invoke).and_raise('migration error')

        expect_any_instance_of(KDK::Announcements).not_to receive(:render_all)

        expect { subject.run }
          .to output(/ERROR: migration error\nERROR: Failed to update/).to_stderr
          .and output(/You can try the following that may be of assistance/).to_stdout
      end
    end

    context 'when reconfigure fails' do
      it 'returns false' do
        expect(subject).to receive(:run_rake).with('kdk:migrate').and_return(true)
        expect(subject).to receive(:run_rake).with(:update).and_return(true)
        expect(subject).to receive(:run_rake).with(:reconfigure).and_return(false)
        expect_any_instance_of(KDK::Announcements).not_to receive(:render_all)

        expect(subject.run).to be(false)
      end
    end

    it 'delegates to #update! and executes with success' do
      expect(subject).to receive(:update!).and_return('some content')
      expect(subject).to receive(:run_rake).with(:reconfigure).and_return(true)
      expect(KDK::Output).to receive(:success).with('Successfully updated!')

      expect(subject.run).to be(true)
    end

    it 'prints a duration summary' do
      task = instance_double(Rake::Task, invoke: nil)
      allow(Rake::Task).to receive(:[]).with(:update).and_return(task)
      expect(KDK::Output).to receive(:success).with('Successfully updated!')

      subject.run
    end

    context 'when kdk.auto_reconfigure flag is disabled' do
      before do
        yaml = {
          'kdk' => {
            'auto_reconfigure' => false
          }
        }
        stub_kdk_yaml(yaml)
      end

      it 'does not execute reconfigure command after update' do
        expect(subject).to receive(:update!).and_return('some content')
        expect(subject).not_to receive(:run_rake).with(:reconfigure)
        expect(KDK::Output).to receive(:success).with('Successfully updated!')

        subject.run
      end
    end

    context 'when `kdk` command no longer available after update' do
      let(:kdk_available_after_update?) { false }

      it 'prints an error' do
        expect(subject).to receive(:update!).and_return(true)
        expect(subject).to receive(:run_rake).with(:reconfigure).and_return(true)
        expect(KDK::Telemetry).to receive(:capture_exception).with(described_class::GdkNotFoundError.new('`kdk` command is no longer available'))
        expect(KDK::Output).to receive(:error).with('The `kdk` is no longer available after `kdk update`. This is unexpected, please report this in https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/2388.')

        subject.run
      end
    end
  end
end
