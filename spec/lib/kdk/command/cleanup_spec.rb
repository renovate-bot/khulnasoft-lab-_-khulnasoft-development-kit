# frozen_string_literal: true

RSpec.describe KDK::Command::Cleanup do
  let(:software_to_uninstall) do
    {
      'ruby' => { '1.2' => :unused },
      'nodejs' => { '1.2.3' => :unused, '0.1.2' => :unused }
    }
  end

  subject { described_class.new }

  before do
    asdf_tool_versions_double =
      instance_double(Asdf::ToolVersions, unnecessary_installed_versions_of_software: software_to_uninstall)
    allow(Asdf::ToolVersions).to receive(:new).and_return(asdf_tool_versions_double)
  end

  describe '#run' do
    context 'when not confirmed' do
      it 'returns true' do
        stub_prompt('n')

        expect_warn_and_puts
        expect(subject).not_to receive(:execute)

        expect(subject.run).to be_truthy
      end
    end

    context 'without software to uninstall' do
      let(:software_to_uninstall) { {} }

      it 'does not show uninstall software messages' do
        stub_prompt('n')

        expect_warn_and_puts(show_uninstall_software: false)
        expect(subject).not_to receive(:execute)

        expect(subject.run).to be_truthy
      end
    end

    context 'when confirmed' do
      context 'but an unhandled error occurs' do
        it 'calls execute but returns false' do
          exception = StandardError.new('a failure occured')
          stub_prompt('y')

          rake_truncate_double = stub_rake_truncate
          allow(rake_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          expect_warn_and_puts
          expect(KDK::Output).to receive(:error).with(exception)

          rake_uninstall_double = stub_rake_uninstall
          expect(rake_uninstall_double).not_to receive(:invoke).with('false')

          expect(subject.run).to be_falsey
        end
      end

      context 'but a RuntimeError error occurs' do
        it 'calls execute, handles the RuntimeError and returns true' do
          exception = RuntimeError.new('a failure occured')
          stub_prompt('y')

          rake_truncate_double = stub_rake_truncate
          allow(rake_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          rake_http_router_truncate_double = stub_rake_http_router_truncate
          allow(rake_http_router_truncate_double).to receive(:invoke).with('false').and_raise(exception)

          expect_warn_and_puts

          expect(KDK::Output).to receive(:error).twice.with('a failure occured', exception)

          expect_rake_uninstall

          expect(subject.run).to be_truthy
        end
      end

      context 'and without any errors' do
        context 'via direct response' do
          it 'calls execute' do
            stub_prompt('y')

            expect_warn_and_puts
            expect_rake_truncate_and_uninstall

            expect(subject.run).to be_truthy
          end
        end

        context 'by setting KDK_CLEANUP_CONFIRM to true' do
          it 'calls execute' do
            stub_env('KDK_CLEANUP_CONFIRM', 'true')

            expect_warn_and_puts
            expect_rake_truncate_and_uninstall

            expect(subject.run).to be_truthy
          end
        end

        context 'by setting KDK_CLEANUP_SOFTWARE to false', :hide_output do
          it 'does not prompt about uninstalling unnecessary software' do
            stub_env('KDK_CLEANUP_SOFTWARE', 'false')
            stub_prompt('n')
            expect(KDK::Output).not_to receive(:puts).with(
              '- Uninstall any asdf software that is not defined in .tool-versions', stderr: true
            )
            expect(subject.run).to be_truthy
          end

          it 'does not uninstall unnecessary software' do
            stub_env('KDK_CLEANUP_SOFTWARE', 'false')
            stub_prompt('y')
            allow(stub_rake_truncate).to receive(:invoke)
            allow(stub_rake_http_router_truncate).to receive(:invoke)

            expect(stub_rake_uninstall).not_to receive(:invoke)
            expect(subject.run).to be_truthy
          end
        end

        context 'by setting KDK_CLEANUP_SOFTWARE to true', :hide_output do
          it 'uninstalls unnecessary software' do
            stub_env('KDK_CLEANUP_SOFTWARE', 'true')
            stub_prompt('y')
            allow(stub_rake_truncate).to receive(:invoke)
            allow(stub_rake_http_router_truncate).to receive(:invoke)

            expect(stub_rake_uninstall).to receive(:invoke)
            expect(subject.run).to be_truthy
          end
        end
      end
    end

    def expect_warn_and_puts(show_uninstall_software: true)
      expect(KDK::Output).to receive(:warn).with('About to perform the following actions:').ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
      expect_truncate_puts

      if show_uninstall_software
        expect(KDK::Output).to receive(:puts).with(
          '- Uninstall any asdf software that is not defined in .tool-versions:', stderr: true
        ).ordered
        software_to_uninstall.sort_by { |n, _| n }.each do |name, versions|
          expect(KDK::Output).to receive(:puts).with("#{name} #{versions.keys.join(' ')}").ordered
        end
        expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
        expect(KDK::Output).to receive(:puts)
          .with('Run `KDK_CLEANUP_SOFTWARE=false kdk cleanup` to skip uninstalling software.').ordered
      end

      expect(KDK::Output).to receive(:puts).with(stderr: true).at_least(:once).ordered
    end

    def expect_truncate_puts
      expect(KDK::Output).to receive(:puts).with('- Truncate khulnasoft/log/* files', stderr: true).ordered
      expect(KDK::Output).to receive(:puts).with("- Truncate #{KDK::Services::KhulnasoftHttpRouter::LOG_PATH} file", stderr: true).ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
    end

    def expect_rake_truncate_and_uninstall
      expect_rake_truncate
      expect_rake_http_router_truncate
      expect_rake_uninstall
    end

    def stub_rake_truncate
      stub_rake_task('khulnasoft:truncate_logs', 'khulnasoft.rake')
    end

    def stub_rake_http_router_truncate
      stub_rake_task('khulnasoft:truncate_http_router_logs', 'khulnasoft.rake')
    end

    def expect_rake_truncate
      expect_rake_task('khulnasoft:truncate_logs', 'khulnasoft.rake', args: 'false')
    end

    def expect_rake_http_router_truncate
      expect_rake_task('khulnasoft:truncate_http_router_logs', 'khulnasoft.rake', args: 'false')
    end

    def stub_rake_uninstall
      stub_rake_task('asdf:uninstall_unnecessary_software', 'asdf.rake')
    end

    def expect_rake_uninstall
      expect_rake_task('asdf:uninstall_unnecessary_software', 'asdf.rake', args: 'false')
    end

    def stub_rake_task(task_name, rake_file)
      allow(Kernel).to receive(:load).with(KDK.root.join('lib', 'tasks', rake_file)).and_return(true)
      rake_task_double = double("#{task_name} rake task") # rubocop:todo RSpec/VerifiedDoubles
      allow(Rake::Task).to receive(:[]).with(task_name).and_return(rake_task_double)
      rake_task_double
    end

    def expect_rake_task(task_name, rake_file, args: nil)
      rake_task_double = stub_rake_task(task_name, rake_file)
      expect(rake_task_double).to receive(:invoke).with(args).and_return(true)
    end
  end
end
