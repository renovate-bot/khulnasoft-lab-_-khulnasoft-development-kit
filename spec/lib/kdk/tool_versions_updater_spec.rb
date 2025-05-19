# frozen_string_literal: true

require 'spec_helper'

RSpec.describe KDK::ToolVersionsUpdater do
  subject(:updater) { described_class.new }

  describe '.enabled_services' do
    subject(:enabled_services) { described_class.enabled_services }

    it { is_expected.to include('rails-web') }

    it 'returns a dup each time' do
      expect(enabled_services.object_id).not_to eq(described_class.enabled_services.object_id)
    end
  end

  describe '#run' do
    let(:khulnasoft_branch) { 'master' }
    let(:khulnasoft_shell_version) { 'v1.0.0' }
    let(:gitaly_version) { 'a' * 40 }
    let(:khulnasoft_url) { "https://gitlab.com/gitlab-org/gitlab/-/raw/#{khulnasoft_branch}/.tool-versions" }
    let(:khulnasoft_shell_url) { "https://gitlab.com/gitlab-org/gitlab-shell/-/raw/#{khulnasoft_shell_version}/.tool-versions" }
    let(:gitaly_url) { "https://gitlab.com/gitlab-org/gitaly/-/raw/#{gitaly_version}/.tool-versions" }

    before do
      allow(KDK.config).to receive_message_chain(:gitlab, :default_branch).and_return(khulnasoft_branch)
      allow(KDK.config).to receive_message_chain(:khulnasoft_shell, :__version).and_return(khulnasoft_shell_version)
      allow(KDK.config).to receive_message_chain(:gitaly, :__version).and_return(gitaly_version)

      allow(described_class).to receive(:enabled_services).and_return(%w[gitaly])

      allow(updater).to receive(:git_fetch_version_files)
      allow(updater).to receive(:install_tools)
      allow(updater).to receive(:cleanup)

      allow(updater).to receive(:http_get).with(khulnasoft_url).and_return("nodejs 20.12.2\nruby 3.3.7 3.2.4\nrust 1.73.0")
      allow(updater).to receive(:http_get).with(khulnasoft_shell_url).and_return("ruby 3.3.0\ngolang 1.24.1")
      allow(updater).to receive(:http_get).with(gitaly_url).and_return("# Tool versions used by Gitaly\ngolang 1.23.6\nruby 3.3.7")

      allow(updater).to receive(:root_tool_versions).and_return([
        ['markdownlint-cli2', '0.17.1'],
        ['vale', '3.9.3']
      ])

      allow(KDK::Output).to receive(:info)
      allow(KDK::Output).to receive(:debug)
      allow(KDK::Output).to receive(:success)
    end

    context 'when mise is enabled' do
      before do
        allow(KDK).to receive_message_chain(:config, :mise, :enabled?).and_return(true)
        allow(KDK).to receive_message_chain(:config, :asdf, :opt_out?).and_return(true)
      end

      it 'writes correct tool versions to combined file and sets mise env vars' do
        expected_content = <<~CONTENT
          golang 1.23.6 1.24.1
          ruby 3.3.7 3.2.4 3.3.0
          nodejs 20.12.2
          rust 1.73.0
          markdownlint-cli2 0.17.1
          vale 3.9.3
        CONTENT

        expect(File).to receive(:write).with(described_class::COMBINED_TOOL_VERSIONS_FILE, expected_content)

        updater.run

        expect(ENV.fetch('MISE_OVERRIDE_TOOL_VERSIONS_FILENAMES')).to eq(described_class::COMBINED_TOOL_VERSIONS_FILE)
        expect(ENV.fetch('MISE_RUST_VERSION')).to eq('1.73.0')
        expect(ENV.fetch('RUST_WITHOUT')).to eq('rust-docs')
      end
    end

    context 'when asdf is enabled' do
      before do
        allow(KDK).to receive_message_chain(:config, :mise, :enabled?).and_return(false)
        allow(KDK).to receive_message_chain(:config, :asdf, :opt_out?).and_return(false)
      end

      it 'sets asdf env vars' do
        expect(File).to receive(:write).with(described_class::COMBINED_TOOL_VERSIONS_FILE, anything)

        updater.run

        expect(ENV.fetch('ASDF_DEFAULT_TOOL_VERSIONS_FILENAME')).to eq(described_class::COMBINED_TOOL_VERSIONS_FILE)
        expect(ENV.fetch('ASDF_RUST_VERSION')).to eq('1.73.0')
        expect(ENV.fetch('RUST_WITHOUT')).to eq('rust-docs')
      end
    end

    context 'when should_update? returns false' do
      before do
        allow(updater).to receive(:should_update?).and_return(false)
      end

      it 'skips the update and returns a message' do
        expect(updater).to receive(:skip_message)
        expect(updater).not_to receive(:collect_tool_versions)

        updater.run
      end
    end
  end
end
