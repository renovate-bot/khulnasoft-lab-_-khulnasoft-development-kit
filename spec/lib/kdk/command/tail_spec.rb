# frozen_string_literal: true

RSpec.describe KDK::Command::Tail do
  context 'with no extra arguments' do
    it 'asks runit to tail logs for all enabled services' do
      expect(Runit).to receive(:tail)

      subject.run
    end
  end

  context 'with extra arguments' do
    it 'asks runit to tail logs for specific services only' do
      services = %w[rails-web]
      expect(Runit).to receive(:tail).with(services)

      subject.run(services)
    end
  end

  context 'with --help flag' do
    let(:kdk_root) { Pathname.new('/home/git/kdk') }
    let(:args) { %w[--help] }
    let(:log_dir) { Pathname.new(kdk_root) }
    let(:log_pathnames) do
      %w[rails-web redis].map do |log|
        Pathname.new(File.join(kdk_root, "log/#{log}"))
      end
    end

    let(:log_shortcuts) do
      {
        'rails' => 'rails*',
        'gitaly' => 'gitaly*'
      }
    end

    let(:output) do
      <<~MSG
        Usage: kdk tail [[--help] | [<log_or_shortcut>[ <...>]]

        Tail command:

          kdk tail                                                  # Tail all log files (stdout and stderr only)
          kdk tail <log_or_shortcut>[ <...>]                        # Tail specified log files (stdout and stderr only)
          kdk tail --help                                           # Print this help text

        Available logs:

          rails-web
          redis

        Shortcuts:

          gitaly                                                    # gitaly*
          rails                                                     # rails*

        To contribute to KhulnaSoft, see
        https://docs.khulnasoft.com/ee/development/index.html.
      MSG
    end

    before do
      allow(KDK).to receive(:root).and_return(kdk_root)
      stub_const('Runit::LOG_DIR', log_dir)
      stub_const('Runit::SERVICE_SHORTCUTS', log_shortcuts)
      allow(log_dir).to receive(:children).and_return(log_pathnames)
    end

    describe '#run' do
      it 'displays help and returns true' do
        expect(KDK::Output).to receive(:puts).with(output)
        expect(subject.run(args)).to be(true)
      end
    end
  end
end
