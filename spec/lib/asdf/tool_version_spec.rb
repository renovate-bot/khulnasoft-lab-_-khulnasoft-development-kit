# frozen_string_literal: true

RSpec.describe Asdf::ToolVersion do
  include ShelloutHelper

  let(:name) { 'golang' }
  let(:version) { '1.17.2' }

  subject { described_class.new(name, version) }

  describe '#name' do
    it 'returns golang' do
      expect(subject.name).to eq(name)
    end
  end

  describe '#version' do
    it 'returns 1.17.2' do
      expect(subject.version).to eq(version)
    end
  end

  describe '#uninstall!' do
    let(:success) { nil }
    let(:shellout_double) { kdk_shellout_double(success?: success) }

    before do
      allow_kdk_shellout_command("asdf uninstall #{name} #{version}").and_return(shellout_double)
      allow(shellout_double).to receive(:execute).and_return(shellout_double)
    end

    context 'when uninstall fails' do
      let(:success) { false }

      it 'raises an UninstallFailedError exception' do
        expect { subject.uninstall! }.to raise_error(Asdf::ToolVersion::UninstallFailedError)
      end
    end

    context 'when uninstall succeeds' do
      let(:success) { true }

      it 'returns true' do
        expect(subject.uninstall!).to be_truthy
      end
    end
  end
end
