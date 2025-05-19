# frozen_string_literal: true

require 'stringio'

RSpec.describe KDK::Command::Doctor, :hide_output do
  # rubocop:todo RSpec/VerifiedDoubles
  let(:successful_diagnostic) do
    double(KDK::Diagnostic, unexpected_error: nil, success?: true, correctable?: false, correct!: nil, message: nil)
  end

  let(:failing_diagnostic) do
    double(KDK::Diagnostic, unexpected_error: nil, success?: false, correctable?: false, correct!: nil, message: 'check failed')
  end

  let(:correctable_diagnostic) do
    double(KDK::Diagnostic, title: 'Correctable Diagnostic', unexpected_error: nil, success?: false, correctable?: true, correct!: nil, message: 'check failed')
  end

  let(:uncorrectable_diagnostic) do
    double(KDK::Diagnostic, title: 'Uncorrectable Diagnostic', unexpected_error: nil, success?: false, correctable?: false, correct!: nil, message: 'check failed')
  end

  let(:shellout) { double(KDK::Shellout, run: nil) }
  # rubocop:enable RSpec/VerifiedDoubles
  let(:diagnostics) { [] }
  let(:args) { [] }
  let(:warning_message) do
    <<~WARNING
      ================================================================================
      Please note these warning only exist for debugging purposes and can
      help you when you encounter issues with KDK.
      If your KDK is working fine, you can safely ignore them. Thanks!
      ================================================================================
    WARNING
  end

  subject { described_class.new(diagnostics: diagnostics) }

  before do
    allow(Runit).to receive(:start).with('postgresql', quiet: true).and_return(true)
    kdk_root_stub = double('KDK_ROOT') # rubocop:todo RSpec/VerifiedDoubles
    procfile_stub = double('Procfile', exist?: true) # rubocop:todo RSpec/VerifiedDoubles
    allow(KDK).to receive(:root).and_return(kdk_root_stub)
    allow(kdk_root_stub).to receive(:join).with('Procfile').and_return(procfile_stub)
    allow_any_instance_of(KDK::Postgresql).to receive(:ready?).and_return(true)
  end

  it 'does not start necessary services' do
    expect(Runit).not_to receive(:start).with('postgresql', quiet: true)

    expect(subject.run).to be(true)
  end

  context 'when postgresql is not ready' do
    before do
      allow_any_instance_of(KDK::Postgresql)
        .to receive(:ready?).with(try_times: 1, quiet: true).and_return(false)
    end

    it 'starts necessary services' do
      expect(Runit).to receive(:start).with('postgresql', quiet: true)
      expect_any_instance_of(KDK::Postgresql).to receive(:ready?)
        .with(try_times: 20, interval: 0.5).and_return(true)

      expect(subject.run).to be(true)
    end

    it 'fails if services cannot be started' do
      expect(Runit).to receive(:start).with('postgresql', quiet: true)
      expect_any_instance_of(KDK::Postgresql).to receive(:ready?)
        .with(try_times: 20, interval: 0.5).and_return(false)

      expect(subject.run).to be(false)
    end
  end

  context 'with passing diagnostics' do
    let(:diagnostics) { [successful_diagnostic, successful_diagnostic] }

    it 'runs all diagnosis' do
      expect(successful_diagnostic).to receive(:success?).twice

      expect(subject.run).to be(true)
    end

    it 'does not check if successful diagnostics are correctable' do
      expect(successful_diagnostic).not_to receive(:correctable?)

      expect(subject.run).to be(true)
    end

    it 'prints KDK is ready.' do
      expect(KDK::Output).to receive(:success).with('Your KDK is healthy.')

      expect(subject.run).to be(true)
    end
  end

  context 'with failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:success?).twice

      expect(subject.run).to be(false)
    end

    it 'checks if failed diagnostics are correctable' do
      expect(failing_diagnostic).to receive(:correctable?).twice

      expect(subject.run).to be(false)
    end

    it 'does not attempt to correct failed diagnostics' do
      expect(failing_diagnostic).not_to receive(:correct!)

      expect(subject.run).to be(false)
    end

    it 'prints a warning' do
      expect(KDK::Output).to receive(:puts).with("\n").ordered
      expect(KDK::Output).to receive(:warn).with('Your KDK may need attention.').ordered
      expect(KDK::Output).to receive(:puts).with('check failed').ordered.twice

      expect(subject.run).to be(false)
    end
  end

  context 'with partial failing diagnostics' do
    let(:diagnostics) { [failing_diagnostic, successful_diagnostic, failing_diagnostic] }

    it 'runs all diagnosis' do
      expect(failing_diagnostic).to receive(:success?).twice
      expect(successful_diagnostic).to receive(:success?).once

      expect(subject.run).to be(false)
    end

    it 'checks if failed diagnostics are correctable' do
      expect(failing_diagnostic).to receive(:correctable?).twice

      expect(subject.run).to be(false)
    end

    it 'does not attempt to correct failed diagnostics' do
      expect(failing_diagnostic).not_to receive(:correct!)

      expect(subject.run).to be(false)
    end

    it 'does not check if successful diagnostics are correctable' do
      expect(successful_diagnostic).not_to receive(:correctable?)

      expect(subject.run).to be(false)
    end

    it 'prints a message from failed diagnostics' do
      expect(failing_diagnostic).to receive(:message).twice
      expect(KDK::Output).to receive(:puts).with("\n").ordered
      expect(KDK::Output).to receive(:warn).with('Your KDK may need attention.').ordered
      expect(KDK::Output).to receive(:puts).with('check failed').ordered.twice

      expect(subject.run).to be(false)
    end

    it 'does not print a message from successful diagnostics' do
      expect(successful_diagnostic).not_to receive(:message)

      expect(subject.run).to be(false)
    end
  end

  context 'with diagnostic that raises an unexpected error' do
    let(:diagnostics) { [successful_diagnostic, failing_diagnostic] }

    it 'prints a message from failed diagnostics' do
      expect(failing_diagnostic).to receive(:success?).and_raise(StandardError, 'some error occurred')
      expect(KDK::Output).to receive(:puts).with("\n").ordered
      expect(KDK::Output).to receive(:warn).with('Your KDK may need attention.').ordered
      expect(KDK::Output).to receive(:puts).with('check failed').ordered.once
      expect(failing_diagnostic).to receive(:unexpected_error=).with(an_instance_of(StandardError))

      expect(subject.run).to be(2)
    end

    it 'returns code 2' do
      expect(failing_diagnostic).to receive(:success?).and_raise(StandardError, 'some error occurred')
      expect(failing_diagnostic).to receive(:unexpected_error=).with(an_instance_of(StandardError))

      expect(subject.run).to be(2)
    end
  end

  context "when passing '--correct' flag" do
    let(:args) { ['--correct'] }

    context 'with correctable diagnostics' do
      let(:diagnostics) { [correctable_diagnostic, correctable_diagnostic] }

      it 'runs all diagnosis' do
        expect(correctable_diagnostic).to receive(:success?).twice

        expect(subject.run(args)).to be(false)
      end

      it 'prints a message from failed diagnostics' do
        expect(correctable_diagnostic).to receive(:message).twice
        expect(KDK::Output).to receive(:puts).with("check failed").twice

        expect(subject.run(args)).to be(false)
      end

      it 'corrects the diagnostics' do
        expect(KDK::Output).to receive(:print).with("Performing correction for 'Correctable Diagnostic' ")
        expect(correctable_diagnostic).to receive(:correct!).twice

        expect(subject.run(args)).to be(false)
      end

      context 'that raise an error' do
        before do
          allow(correctable_diagnostic).to receive(:correct!).and_raise(StandardError, 'error during correction')
        end

        it 'prints an error message' do
          expect(KDK::Output).to receive(:error).with('error during correction', StandardError)

          expect(subject.run(args)).to be(2)
        end

        it('returns code 2') do
          expect(subject.run(args)).to be(2)
        end
      end
    end

    context 'with uncorrectable diagnostics' do
      let(:diagnostics) { [uncorrectable_diagnostic, uncorrectable_diagnostic] }

      it 'runs all diagnosis' do
        expect(uncorrectable_diagnostic).to receive(:success?).twice
        expect(uncorrectable_diagnostic).to receive(:correctable?).twice

        expect(subject.run(args)).to be(false)
      end

      it 'does not attempt to correct the diagnostics' do
        expect(uncorrectable_diagnostic).not_to receive(:correct!)

        expect(subject.run(args)).to be(false)
      end

      it 'warns of no problems to autocorrect' do
        expect(KDK::Output).to receive(:warn).with('No problems to autocorrect.')

        expect(subject.run(args)).to be(false)
      end
    end
  end
end
