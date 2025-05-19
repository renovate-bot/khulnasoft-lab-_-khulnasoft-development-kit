# frozen_string_literal: true

RSpec.describe Asdf::Tool do
  let(:name) { 'golang' }
  let(:versions) { %w[1.17.2 1.17.1] }

  subject { described_class.new(name, versions) }

  describe '#name' do
    it 'returns golang' do
      expect(subject.name).to eq(name)
    end
  end

  describe '#versions' do
    it 'returns [1.17.2, 1.17.1]' do
      expect(subject.versions).to eq(versions)
    end
  end

  describe '#default_version' do
    it 'returns 1.17.2' do
      expect(subject.default_version).to eq('1.17.2')
    end
  end

  describe '#default_tool_version' do
    it 'returns instance of ToolVersion' do
      stubbed_tool_versions = stub_tool_versions

      expect(subject.default_tool_version).to eq(stubbed_tool_versions.first[1])
    end
  end

  describe '#tool_versions' do
    it 'returns a Hash of ToolVersion instances' do
      stubbed_tool_versions = stub_tool_versions

      expect(subject.tool_versions).to eq(stubbed_tool_versions)
    end
  end

  def stub_tool_versions
    tool_version_1_17_2 = instance_double(Asdf::ToolVersion)
    tool_version_1_17_1 = instance_double(Asdf::ToolVersion)

    allow(Asdf::ToolVersion).to receive(:new).with('golang', '1.17.2').and_return(tool_version_1_17_2)
    allow(Asdf::ToolVersion).to receive(:new).with('golang', '1.17.1').and_return(tool_version_1_17_1)

    { '1.17.2' => tool_version_1_17_2, '1.17.1' => tool_version_1_17_1 }
  end
end
