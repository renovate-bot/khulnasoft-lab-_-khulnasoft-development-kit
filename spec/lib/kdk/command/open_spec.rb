# frozen_string_literal: true

RSpec.describe KDK::Command::Open do
  let(:host_os) { nil }
  let(:wsl) { false }
  let(:wait_result) { nil }
  let(:check_url_oneshot_result) { nil }

  let(:test_url_double) { instance_double(KDK::TestURL) }

  before do
    allow(RbConfig::CONFIG).to receive(:[]).with('host_os').and_return(host_os)
    allow(Etc).to receive(:uname).and_return({ release: wsl ? "microsoft" : "not applicable" })

    allow(KDK::Output).to receive(:puts).and_call_original
    allow(KDK::Output).to receive(:puts).with('Opening http://127.0.0.1:3000')

    allow(KDK::TestURL).to receive(:new).and_return(test_url_double)
    allow(test_url_double).to receive_messages(check_url_oneshot: check_url_oneshot_result, wait: wait_result)
  end

  describe '#run' do
    context 'asking for help' do
      it 'prints help and exits' do
        expect { subject.run(%w[--help]) }.to output(/-h, --help          Display help/).to_stdout
      end
    end

    context 'without --wait-until-ready' do
      let(:host_os) { 'Darwin' }

      it 'calls open with <KDK_URL>`' do
        expect(subject).to receive(:exec).with(a_string_ending_with("'http://127.0.0.1:3000'"))

        subject.run
      end
    end

    context 'with --wait-until-ready' do
      context 'when KDK is not up' do
        let(:check_url_oneshot_result) { false }
        let(:wait_result) { false }

        it 'advises KDK is not up and returns' do
          result = nil
          expect { result = subject.run(%w[--wait-until-ready]) }.to output(/KDK is not up. Please run `kdk start` and try again./).to_stderr
          expect(result).to be_falsey
          expect_no_error_report
        end
      end

      context 'when KDK is not up initially, but then comes up' do
        let(:check_url_oneshot_result) { false }
        let(:wait_result) { true }

        it 'advises KDK is not up and returns' do
          expect(subject).to receive(:exec).with(a_string_ending_with("'http://127.0.0.1:3000'"))

          subject.run(%w[--wait-until-ready])
        end
      end

      context 'when KDK is up' do
        let(:check_url_oneshot_result) { true }

        context 'when Linux' do
          let(:host_os) { 'Linux' }

          it 'calls open with <KDK_URL>`' do
            expect(subject).to receive(:exec).with(a_string_ending_with("'http://127.0.0.1:3000'"))

            subject.run(%w[--wait-until-ready])
          end
        end

        context 'when not Linux' do
          let(:host_os) { 'Darwin' }

          it 'calls open <KDK_URL>' do
            expect(subject).to receive(:exec).with(a_string_ending_with("'http://127.0.0.1:3000'"))

            subject.run(%w[--wait-until-ready])
          end
        end

        context 'when WSL' do
          let(:host_os) { 'Linux' }
          let(:wsl) { true }

          it 'calls `pwsh.exe -Command Start-Process <KDK_URL>`' do
            expect(subject).to receive(:exec).with("pwsh.exe -Command Start-Process 'http://127.0.0.1:3000'")

            subject.run(%w[--wait-until-ready])
          end
        end
      end
    end
  end
end
