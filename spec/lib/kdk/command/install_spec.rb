# frozen_string_literal: true

RSpec.describe KDK::Command::Install do
  include ShelloutHelper

  let(:args) { [] }

  before do
    allow(KDK).to receive(:make).with('install', *args).and_return(sh)
  end

  context 'when install fails' do
    let(:sh) { kdk_shellout_double(success?: false, stderr_str: nil) }

    it 'returns an error message' do
      expect { subject.run(args) }.to output(/Failed to install/).to_stderr.and output(/You can try the following that may be of assistance/).to_stdout
    end

    it 'does not render announcements', :hide_output do
      expect_any_instance_of(KDK::Announcements).not_to receive(:render_all)

      subject.run(args)
    end
  end

  context 'when install succeeds' do
    let(:sh) { kdk_shellout_double(success?: true) }

    it 'finishes without problem' do
      expect { subject.run(args) }.not_to raise_error
    end

    it 'renders announcements' do
      expect_any_instance_of(KDK::Announcements).to receive(:cache_all)

      subject.run(args)
    end
  end

  describe 'telemetry' do
    let(:sh) { kdk_shellout_double(success?: true) }

    context 'with telemetry_enabled=true' do
      let(:args) { %w[telemetry_enabled=true] }

      it 'enables telemetry' do
        expect(KDK::Telemetry).to receive(:update_settings).with('y')

        subject.run(args)
      end
    end

    context 'with telemetry_enabled=false' do
      let(:args) { %w[telemetry_enabled=false] }

      it 'disables telemetry' do
        expect(KDK::Telemetry).to receive(:update_settings).with('n')

        subject.run(args)
      end
    end

    context 'without telemetry_enabled argument' do
      let(:args) { [] }

      it 'does not update telemetry settings' do
        expect(KDK::Telemetry).not_to receive(:update_settings)

        subject.run(args)
      end
    end
  end
end
