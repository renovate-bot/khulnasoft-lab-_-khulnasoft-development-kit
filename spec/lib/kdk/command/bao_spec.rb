# frozen_string_literal: true

RSpec.describe KDK::Command::Bao do
  context 'with openbao enabled' do
    before do
      stub_kdk_yaml <<~YAML
        openbao:
          enabled: true
      YAML
    end

    context 'with configure argument' do
      let(:input) { %w[configure] }

      it 'calls configure' do
        expect(KDK::OpenBao).to receive_message_chain(:new, :configure)

        subject.run(input)
      end
    end

    context 'without arguments' do
      it 'does nothing' do
        expect(KDK::OpenBao).not_to receive(:new)
        expect(KDK::Output).to receive(:warn).with('Usage: kdk bao configure')

        subject.run
      end
    end
  end

  context 'with openbao disabled' do
    it 'outputs an error message' do
      expect(KDK::Output).to receive(:warn).with('OpenBao is not enabled. See doc/howto/openbao.md for getting started with OpenBao.')

      subject.run
    end
  end
end
