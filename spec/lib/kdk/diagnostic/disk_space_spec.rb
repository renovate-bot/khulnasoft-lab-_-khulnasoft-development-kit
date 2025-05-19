# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::DiskSpace do
  subject(:diagnostic) { described_class.new }

  let(:gb) { 1000 * 1000 * 1000 }
  let(:available_disk_space) { 200 * gb }

  before do
    allow(KDK::Machine).to receive(:available_disk_space).and_return(available_disk_space)
  end

  it 'passes by default' do
    expect(diagnostic.success?).to be(true)
  end

  context 'when not enough disk space is available' do
    let(:available_disk_space) { 5 * gb }

    it 'reports a warning' do
      expect(diagnostic.success?).to be(false)
      expect(diagnostic.detail).to eq <<~MESSAGE
        You only have 5 GB available on the disk where KDK is installed.

        We recommend that you keep 15 GB available for KDK to work optimally.
      MESSAGE
    end
  end
end
