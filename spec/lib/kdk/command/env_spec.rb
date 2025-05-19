# frozen_string_literal: true

RSpec.describe KDK::Command::Env do
  let(:env) { subject.send(:env) }

  context 'when running from gitaly folder' do
    before do
      allow(subject).to receive(:get_project).and_return('gitaly')
    end

    context 'with no extra arguments' do
      it 'outputs gitaly specific ENV context' do
        expect { subject.run }.to output(/export PGHOST=.+\nexport PGPORT=.+/).to_stdout
      end
    end

    context 'with extra arguments' do
      it 'executes passed arguments withing gitaly specific ENV context' do
        command = 'pdw'

        expect(subject).to receive(:exec).with(env, command, chdir: KDK.pwd)

        subject.run(command)
      end
    end
  end

  context 'when running from main folder or from an unsupported service folder' do
    it 'does not output anything' do
      expect { subject.run }.not_to output.to_stdout
    end
  end
end
