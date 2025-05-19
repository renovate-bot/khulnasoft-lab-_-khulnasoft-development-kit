# frozen_string_literal: true

RSpec.describe KDK::Command::Reconfigure do
  let(:config_diff) { '' }

  before do
    allow(KDK::Diagnostic::Configuration)
      .to receive_message_chain(:new, :config_diff)
      .and_return(config_diff)
    allow(Rake::Task).to receive(:[]).with('kdk-config.mk') do
      instance_double(Rake::Task, invoke: nil)
    end
  end

  context 'when reconfiguration fails' do
    it 'returns an error message' do
      stub_reconfigure(success: false)

      expect { subject.run }.to output(/Failed to reconfigure/).to_stderr.and output(/You can try the following that may be of assistance/).to_stdout
    end
  end

  context 'when reconfiguration succeeds' do
    before do
      stub_reconfigure(success: true)
    end

    it 'finishes without problem' do
      expect(KDK::Output).to receive(:success).with('Successfully reconfigured!')
      expect(KDK::Output).not_to receive(:puts)

      subject.run
    end

    context 'with config diff' do
      let(:config_diff) do
        <<~DIFF
          Procfile
          --------------------------------------------------------------------------------
          diff --git a/Procfile b/home/peter/devel/khulnasoft/kdk/tmp/diff_Procfile
          index de284a64..3ef9c0c3 100644
          --- a/Procfile
          +++ b/home/peter/devel/khulnasoft/kdk/tmp/diff_Procfile
        DIFF
      end

      it 'prints the diff' do
        expect(KDK::Output).to receive(:success).with('Successfully reconfigured!')
        expect(KDK::Output).to receive(:puts)
        expect(KDK::Output).to receive(:puts).with(config_diff)

        subject.run
      end
    end
  end

  def stub_reconfigure(success:)
    expect(Rake::Task).to receive(:[]).with(:reconfigure) do
      instance_double(Rake::Task, invoke: nil).tap do |task|
        expect(task).to receive(:invoke).and_raise(RuntimeError) unless success
      end
    end
  end
end
