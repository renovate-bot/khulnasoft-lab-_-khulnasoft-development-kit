# frozen_string_literal: true

RSpec.describe 'rake asdf:uninstall_unnecessary_software' do
  before(:all) do
    Rake.application.rake_require('tasks/asdf')
  end

  let(:tool_versions) { instance_double(Asdf::ToolVersions) }

  before do
    allow(Asdf::ToolVersions).to receive(:new).and_return(tool_versions)
    allow(tool_versions).to receive(:uninstall_unnecessary_software!)
  end

  context 'when passing prompt=true' do
    it 'prompts the user' do
      task.execute(prompt: 'true')

      expect(tool_versions).to have_received(:uninstall_unnecessary_software!).with(prompt: true)
    end
  end

  context 'when passing prompt=false' do
    it 'does not prompt the user' do
      task.execute(prompt: 'false')

      expect(tool_versions).to have_received(:uninstall_unnecessary_software!).with(prompt: false)
    end
  end

  context 'executing without passing any parameters' do
    it 'does prompt the user' do
      task.execute

      expect(tool_versions).to have_received(:uninstall_unnecessary_software!).with(prompt: true)
    end
  end
end
