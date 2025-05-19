# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::ToolVersionManager do
  let(:asdf_opt_out) { false }
  let(:mise_enabled) { false }
  let(:asdf_version) { 'version: v0.15.0' }
  let(:mise_version_output) do
    {
      'version' => '2025.4.0 macos-arm64 (2025-04-01)',
      'latest' => '2025.4.0'
    }
  end

  let(:is_macos) { true }
  let(:is_linux) { false }

  before do
    allow(subject).to receive_messages(current_asdf_version: asdf_version, mise_version_output: mise_version_output, current_mise_version: mise_version_output['version'].split.first)
    allow(KDK.config).to receive_message_chain(:asdf, :opt_out?).and_return(asdf_opt_out)
    allow(KDK.config).to receive_message_chain(:mise, :enabled?).and_return(mise_enabled)
    allow(KDK::Machine).to receive_messages(macos?: is_macos, linux?: is_linux)
  end

  describe '#success?' do
    context 'when mise is enabled and asdf is opted out' do
      let(:asdf_opt_out) { true }
      let(:mise_enabled) { true }

      it 'returns true when mise is up to date' do
        expect(subject).to be_success
      end

      context 'when mise needs updating' do
        let(:mise_version_output) do
          {
            'version' => '2025.1.0 macos-arm64 (2025-01-01)',
            'latest' => '2025.4.0'
          }
        end

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end
    end

    context 'when a custom tool version manager is used' do
      let(:asdf_opt_out) { true }
      let(:mise_enabled) { false }

      it 'returns true' do
        expect(subject).to be_success
      end
    end

    context 'when asdf is enabled and mise is disabled' do
      let(:asdf_opt_out) { false }
      let(:mise_enabled) { false }

      it 'returns false' do
        expect(subject).not_to be_success
      end
    end
  end

  describe '#correctable?' do
    context 'when mise is enabled and needs updating' do
      let(:asdf_opt_out) { true }
      let(:mise_enabled) { true }
      let(:mise_version_output) do
        {
          'version' => '2023.2.0 macos-arm64 (2023-02-01)',
          'latest' => '2025.4.0'
        }
      end

      context 'on macOS' do
        let(:is_macos) { true }
        let(:is_linux) { false }

        it 'returns true' do
          expect(subject).to be_correctable
        end
      end

      context 'on Linux' do
        let(:is_macos) { false }
        let(:is_linux) { true }

        it 'returns true' do
          expect(subject).to be_correctable
        end
      end

      context 'on unsupported OS' do
        let(:is_macos) { false }
        let(:is_linux) { false }

        it 'returns false' do
          expect(subject).not_to be_correctable
        end
      end
    end

    context 'when mise is enabled but already up to date' do
      let(:asdf_opt_out) { true }
      let(:mise_enabled) { true }

      it 'returns false' do
        expect(subject).not_to be_correctable
      end
    end

    context 'when asdf is being used' do
      let(:asdf_opt_out) { false }
      let(:mise_enabled) { false }

      it 'returns true' do
        expect(subject).to be_correctable
      end
    end
  end

  describe '#correct!' do
    let(:asdf_opt_out) { true }
    let(:mise_enabled) { true }
    let(:mise_version_output) do
      {
        'version' => '2024.5.3 macos-arm64 (2024-05-01)',
        'latest' => '2025.4.4'
      }
    end

    let(:shellout) { instance_double(KDK::Shellout) }

    context 'on macOS' do
      let(:is_macos) { true }
      let(:is_linux) { false }

      before do
        allow(KDK::Shellout).to receive(:new).with('brew update && brew upgrade mise').and_return(shellout)
      end

      it 'updates mise successfully with brew command' do
        expect(shellout).to receive(:execute).with(display_output: false).and_return(shellout)
        expect(subject.correct!).to be true
      end

      context 'when update fails' do
        before do
          allow(shellout).to receive(:execute).with(display_output: false).and_raise(StandardError.new('update failed'))
          allow(KDK::Output).to receive(:warn)
        end

        it 'logs warning and returns false' do
          expect(subject.correct!).to be false
          expect(KDK::Output).to have_received(:warn).with('Failed to update mise: update failed')
        end
      end
    end

    context 'on Linux' do
      let(:is_macos) { false }
      let(:is_linux) { true }

      before do
        allow(KDK::Shellout).to receive(:new).with('apt update && apt upgrade mise').and_return(shellout)
      end

      it 'updates mise successfully with apt command' do
        expect(shellout).to receive(:execute).with(display_output: false).and_return(shellout)
        expect(subject.correct!).to be true
      end
    end
  end

  describe '#detail' do
    context 'when mise is enabled and asdf is opted out' do
      let(:asdf_opt_out) { true }
      let(:mise_enabled) { true }

      it 'returns no message when mise is up to date' do
        expect(subject.detail).to be_nil
      end

      context 'when mise needs updating' do
        let(:mise_version_output) do
          {
            'version' => '2024.1.0 macos-arm64 (2024-01-02)',
            'latest' => '2024.4.0'
          }
        end

        context 'on macOS' do
          let(:is_macos) { true }
          let(:is_linux) { false }

          it 'returns a warning message with brew update instructions' do
            expected = <<~MESSAGE
              WARNING: Your installed version of mise (2024.1.0) is out of date.
              The latest available version is 2024.4.0.

              To update to the latest version, run:
                `brew update && brew upgrade mise`
            MESSAGE

            expect(subject.detail).to eq(expected)
          end
        end

        context 'on Linux' do
          let(:is_macos) { false }
          let(:is_linux) { true }

          it 'returns a warning message with apt update instructions' do
            expected = <<~MESSAGE
              WARNING: Your installed version of mise (2024.1.0) is out of date.
              The latest available version is 2024.4.0.

              To update to the latest version, run:
                `apt update && apt upgrade mise`
            MESSAGE

            expect(subject.detail).to eq(expected)
          end
        end

        context 'on unsupported OS' do
          let(:is_macos) { false }
          let(:is_linux) { false }

          it 'returns a warning message without update instructions' do
            expected = <<~MESSAGE
              WARNING: Your installed version of mise (2024.1.0) is out of date.
              The latest available version is 2024.4.0.
            MESSAGE

            expect(subject.detail).to eq(expected)
          end
        end
      end
    end

    context 'when a custom tool version manager is used' do
      let(:asdf_opt_out) { true }
      let(:mise_enabled) { false }

      it 'returns no message' do
        expect(subject.detail).to be_nil
      end
    end

    context 'when asdf is enabled and mise is disabled' do
      let(:asdf_opt_out) { false }
      let(:mise_enabled) { false }

      it 'returns a message with migration instructions by default' do
        expected = <<~MESSAGE
          We're dropping support for asdf in KDK.

          You can still use asdf if you need to, for example outside of KDK. But it's no longer supported in KDK and won't be maintained going forward.

          Mise provides better supply chain security while running faster and avoiding the dependency installation problems that we had to manually fix with asdf.

          To migrate, run:
            kdk update
        MESSAGE

        expect(subject.detail).to eq(expected)
      end

      context 'when context is :update' do
        it 'returns a message without migration instructions' do
          expected = <<~MESSAGE
            We're dropping support for asdf in KDK.

            You can still use asdf if you need to, for example outside of KDK. But it's no longer supported in KDK and won't be maintained going forward.

            Mise provides better supply chain security while running faster and avoiding the dependency installation problems that we had to manually fix with asdf.
          MESSAGE

          expect(subject.detail(:update)).to eq(expected)
        end
      end

      context 'with broken asdf version' do
        let(:asdf_version) { 'version: v0.16.0' }

        it 'returns an additional error' do
          expect(subject.detail).to include(<<~ERROR)
            ERROR: Your installed version of asdf (`#{asdf_version}`) has a bug that makes it incompatible with KDK.
            Please downgrade to `v0.15.0` or switch to `mise`.

            We're dropping support for asdf in KDK.
          ERROR
        end
      end
    end
  end

  describe '#mise_update_required?' do
    let(:asdf_opt_out) { true }
    let(:mise_enabled) { true }

    context 'when mise version data is complete' do
      context 'when current version is less than latest version' do
        let(:mise_version_output) do
          {
            'version' => '2023.1.0 macos-arm64 (2023-01-02)',
            'latest' => '2024.4.0'
          }
        end

        it 'returns true' do
          expect(subject.send(:mise_update_required?)).to be true
        end
      end

      context 'when current version equals latest version' do
        let(:mise_version_output) do
          {
            'version' => '2024.4.0 macos-arm64 (2024-04-02)',
            'latest' => '2024.4.0'
          }
        end

        it 'returns false' do
          expect(subject.send(:mise_update_required?)).to be false
        end
      end

      context 'when current version is greater than latest version' do
        let(:mise_version_output) do
          {
            'version' => '2025.5.3 macos-arm64 (2025-05-01)',
            'latest' => '2025.4.4'
          }
        end

        it 'returns false' do
          expect(subject.send(:mise_update_required?)).to be false
        end
      end
    end

    context 'when not using mise' do
      let(:mise_enabled) { false }

      it 'returns false' do
        expect(subject.send(:mise_update_required?)).to be false
      end
    end
  end

  describe '#mise_update_command' do
    context 'on macOS' do
      let(:is_macos) { true }
      let(:is_linux) { false }

      it 'returns brew command' do
        expect(subject.send(:mise_update_command)).to eq('brew update && brew upgrade mise')
      end
    end

    context 'on Linux' do
      let(:is_macos) { false }
      let(:is_linux) { true }

      it 'returns apt command' do
        expect(subject.send(:mise_update_command)).to eq('apt update && apt upgrade mise')
      end
    end

    context 'on unsupported OS' do
      let(:is_macos) { false }
      let(:is_linux) { false }

      it 'returns nil' do
        expect(subject.send(:mise_update_command)).to be_nil
      end
    end
  end
end
