# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::OldMiseHooks do
  subject(:diagnostic) { described_class.new }

  before do
    allow(File).to receive(:read).with(KDK.config.kdk_root.join('lefthook-local.yml')) { contents }
  end

  context 'with no lefthook-local.yml file present' do
    let(:contents) { raise Errno::ENOENT }

    it 'passes' do
      expect(diagnostic.success?).to be(true)
    end
  end

  context 'with lefthook-local.yml present' do
    let(:contents) do
      <<~YAML
        post-merge:
          commands:
            inform-me:
              run: say 'post merge done'
      YAML
    end

    it 'passes' do
      expect(diagnostic.success?).to be(true)
    end

    context 'that contains the old mise hook' do
      let(:contents) do
        <<~YAML
          post-merge:
            commands:
              mise-install:
                run: mise plugins update ruby; mise install
        YAML
      end

      it 'reports a warning' do
        expect(diagnostic.success?).to be(false)
        expect(diagnostic.detail).to eq <<~MESSAGE
          Your lefthook-local.yml contains legacy tasks to update mise plugins.

          You can safely remove the task(s) referencing this command from lefthook-local.yml:

            mise plugins update ruby; mise install
        MESSAGE
      end
    end
  end
end
