# frozen_string_literal: true

RSpec.describe KDK::Command::Help do
  let(:kdk_root) { Pathname.new('/home/git/kdk') }
  let(:args) { [] }

  before do
    allow(KDK).to receive(:root).and_return(kdk_root)
  end

  describe '#run' do
    it 'displays help and returns true' do
      help_file = kdk_root.join('HELP')
      help_file_contents = 'help contents'

      allow(KDK::Logo).to receive(:print)
      allow(File).to receive(:read).with(help_file).and_return(help_file_contents)

      expect(KDK::Output).to receive(:puts).with(help_file_contents)
      expect(subject.run(args)).to be(true)
    end
  end
end
