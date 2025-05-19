# frozen_string_literal: true

RSpec.describe KDK::Command::Report, :kdk_root do
  include ShelloutHelper

  let(:kdk_report) { described_class.new }
  let(:kdk_root) { Pathname.new('/home/git/kdk') }
  let(:report_template_dir) { Pathname.new('kdk/lib/support/files') }
  let(:report_template_file) { KDK.root.join(described_class::REPORT_TEMPLATE_PATH) }
  let(:args) { [] }
  let(:shellout) { double(run: true) } # rubocop:todo RSpec/VerifiedDoubles
  let(:debug_info) { KDK::Command::DebugInfo.new }

  let(:report_id) { SecureRandom.uuid }
  let(:package_manager) { 'mise-en-place' }
  let(:env_variables) { { 'PATH' => '/usr/local/bin', 'KDK_VERSION' => '0.2.0' } }
  let(:kdk_config) { { 'config' => 'value' } }
  let(:kdk_doctor) { 'KDK Doctor output' }
  let(:gem_env) { 'Gem environment' }
  let(:bundle_env) { 'Bundle environment' }
  let(:network_information) { 'Network information' }
  let(:logs) { { 'service1' => 'Log content' } }
  let(:git_status) { kdk_report.git_status('repo1') }
  let(:git_head) { kdk_report.git_head('repo1') }
  let(:git_repositories) { { 'repo1' => { git_status: git_status, git_head: git_head } } }
  let(:date_time) { Time.now.strftime('%d/%m/%Y %H:%M:%S %Z') }

  let(:report_json) do
    {
      report_id: report_id,
      os_name: debug_info.os_name,
      arch: debug_info.arch,
      ruby_version: debug_info.ruby_version,
      kdk_version: debug_info.kdk_version,
      package_manager: package_manager,
      env_variables: env_variables,
      kdk_config: kdk_config,
      kdk_doctor: kdk_doctor,
      gem_env: gem_env,
      bundle_env: bundle_env,
      network_information: network_information,
      logs: logs,
      git_repositories: git_repositories,
      date_time: date_time
    }
  end

  subject { kdk_report.run(args) }

  describe '#run' do
    before do
      allow(KDK.config.mise).to receive(:enabled?).and_return(true)
      allow(KDK.config).to receive(:kdk_root).and_return(kdk_root)
      allow(KDK.root).to receive(:join).with(described_class::REPORT_TEMPLATE_PATH)
                                       .and_return(report_template_file)

      allow(kdk_report).to receive_messages(
        report_id: report_id,
        package_manager: package_manager,
        env_variables: env_variables,
        kdk_config: kdk_config,
        kdk_doctor: kdk_doctor,
        gem_env: gem_env,
        bundle_env: bundle_env,
        network_information: network_information,
        logs: logs,
        git_repositories: git_repositories,
        git_status: { repo1: 'clean' },
        git_head: { repo1: 'commit_hash' },
        date_time: date_time
      )

      allow(KDK::Templates::ErbRenderer).to receive(:new).with(report_template_file, report_json: report_json)
        .and_call_original

      allow(kdk_report).to receive(:open_browser)
      allow(kdk_report).to receive(:copy_clipboard)
    end

    it 'displays the generated report and returns true' do
      expect_output(:info, message: 'We are collecting report details, this might take a minute ...')
      expect_output_to_include('## Environment')

      expect_output(:info, message: 'This report has been copied to your clipboard.')
      expect_output(
        :info, message: 'We opened the browser with a new issue, please paste this report from your clipboard into the description.'
      )

      expect(subject).to be(true)
    end
  end

  def expect_output(level, message: nil)
    expect(KDK::Output).to receive(level).with(message || no_args)
  end

  def expect_output_to_include(message)
    expect(KDK::Output).to receive(:puts).with(include(message))
  end
end
