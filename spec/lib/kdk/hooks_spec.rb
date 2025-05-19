# frozen_string_literal: true

RSpec.describe KDK::Hooks do
  context 'hooks behavior' do
    describe '#execute_hooks' do
      it 'calls execute_hook_cmd for each cmd and returns true' do
        cmd = 'echo'
        description = 'example'

        allow(subject).to receive(:execute_hook_cmd).with(cmd, description).and_return(true)

        expect(subject.execute_hooks([cmd], description)).to be(true)
      end
    end

    describe '#execute_hook_cmd' do
      let(:cmd) { 'echo' }
      let(:description) { 'example' }

      before do
        stub_tty(false)
      end

      context 'when cmd is not a string' do
        it 'aborts with error message' do
          error_message = %(ERROR: Cannot execute 'example' hook '\\["echo"\\]')

          expect { subject.execute_hook_cmd([cmd], description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
        end
      end

      context 'when cmd is a string' do
        context 'when cmd does not exist' do
          it 'aborts with error message', :hide_stdout do
            error_message = %(ERROR: No such file or directory - fail)

            expect { subject.execute_hook_cmd('fail', description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
          end
        end

        context 'when cmd fails' do
          it 'aborts with error message', :hide_stdout do
            error_message = %(ERROR: 'false' has exited with code 1.)

            expect { subject.execute_hook_cmd('false', description) }.to raise_error(/#{error_message}/).and output(/#{error_message}/).to_stderr
          end
        end

        context 'when cmd succeeds' do
          it 'returns true', :hide_stdout do
            expect(subject.execute_hook_cmd(cmd, description)).to be(true)
          end
        end
      end
    end

    describe '#with_hooks' do
      it 'returns true' do
        before_hooks = %w[date]
        after_hooks = %w[uptime]
        hooks = { before: before_hooks, after: after_hooks }
        name = 'example'

        expect(subject).to receive(:execute_hooks).with(before_hooks, "#{name}: before").and_return(true)
        expect(subject).to receive(:execute_hooks).with(after_hooks, "#{name}: after").and_return(true)

        expect(subject.with_hooks(hooks, name) { true }).to be(true)
      end
    end
  end
end
