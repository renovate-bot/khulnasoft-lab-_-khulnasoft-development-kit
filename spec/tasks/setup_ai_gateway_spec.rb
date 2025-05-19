# frozen_string_literal: true

RSpec.describe 'rake setup_ai_gateway', :hide_output do
  let(:env_file) { AI_GATEWAY_ENV_FILE }
  let(:env_runit_file) { ENV_RUNIT_FILE }
  let(:log_file) { LOG_FILE }
  let(:gateway_enabled) { false }
  let(:raw_yaml) { "---\nkhulnasoft_ai_gateway:\n  enabled: #{gateway_enabled}\nkdk:\n  root: /path/to/kdk" }

  before(:all) do
    Rake.application.rake_require('tasks/setup_ai_gateway')
  end

  before do
    stub_raw_kdk_yaml(raw_yaml)
    allow(KDK::Output).to receive(:prompt).and_return('test_input')
    allow(File).to receive_messages(write: nil, exist?: false, read: '', open: nil)
    allow(File).to receive(:file?).with(env_file.to_s).and_return(true)
    allow(KDK.config).to receive(:bury!).with('khulnasoft_ai_gateway.enabled', true)
    allow(KDK.config).to receive(:save_yaml!)
    allow_any_instance_of(KDK::Command::Update).to receive(:run).and_return(true)
    allow_any_instance_of(KDK::Command::Restart).to receive(:run)
    allow(KDK).to receive(:make).with('khulnasoft-ai-gateway-gcloud-setup')
  end

  context 'when running the task' do
    before do
      allow(KDK::Output).to receive(:prompt).with('Enter your Anthropic API key').and_return('test_api_key')
      allow(KDK::Output).to receive(:prompt)
        .with('Do you want to set additional environment variables for debugging? [y/N]')
        .and_return('y')
      allow(KDK::Output).to receive(:prompt)
        .with('Do you want to enable Duo Features in SaaS (KhulnaSoft.com) Mode? [y/N]')
        .and_return('y')
      allow(KDK::Output).to receive(:prompt)
        .with('Do you want to enable hot reload?[y/N]')
        .and_return('y')
      allow(File).to receive(:exist?).with(env_file.to_s).and_return(false)
    end

    it 'configures AI Gateway, updates environment, and restarts services' do
      expect(KDK.config).to receive(:bury!).with('khulnasoft_ai_gateway.enabled', true)
      expect(KDK.config).to receive(:save_yaml!)
      expect(File).to receive(:write).with(env_file.to_s, "ANTHROPIC_API_KEY=test_api_key\n").ordered
      expect(KDK).to receive(:make).with('khulnasoft-ai-gateway-gcloud-setup')
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_LOGGING__LEVEL=debug\n")
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_LOGGING__FORMAT_JSON=false\n")
      expect(File).to receive(:write).with(
        env_file.to_s,
        %r{AIGW_LOGGING__TO_FILE=.*/log/khulnasoft-ai-gateway/gateway_debug\.log\n}
      )
      expect(File).to receive(:write).with(env_file.to_s, "AIGW_FASTAPI__RELOAD=true\n")
      expect(File).to receive(:open).with(env_runit_file.to_s, 'a')

      task.execute
    end
  end

  context 'when exporting env_runit variables' do
    let(:env_runit_contents) { '' }

    before do
      allow(KDK::Output).to receive(:prompt).with(/Do you want to enable Duo Features in SaaS \(KhulnaSoft\.com\) Mode?/).and_return('y')
      allow(File).to receive(:exist?).with(env_runit_file.to_s).and_return(true)
      allow(File).to receive(:read).with(env_runit_file.to_s).and_return(env_runit_contents)
    end

    shared_examples 'writes correct content' do |saas_input, expected_saas_value|
      before do
        allow(KDK::Output).to receive(:prompt).with(/Do you want to enable Duo Features in SaaS \(KhulnaSoft\.com\) Mode?/).and_return(saas_input)
      end

      it "writes correct content for saas_mode_enabled '#{saas_input}'" do
        allow(File).to receive(:open).with(env_runit_file.to_s, 'a') do |file|
          expect(file).to receive(:write).with("export KHULNASOFT_SIMULATE_SAAS=#{expected_saas_value}\n")
          expect(file).to receive(:write).with("export AI_GATEWAY_URL=http://0.0.0.0:5052\n")
        end
      end
    end

    context 'when env_runit_contents is empty' do
      let(:env_runit_contents) { '' }

      it_behaves_like 'writes correct content', 'y', '1'
      it_behaves_like 'writes correct content', 'n', '0'
    end

    context 'when KHULNASOFT_SIMULATE_SAAS is not present' do
      let(:env_runit_contents) { 'EXISTING_VAR=value\n' }

      it_behaves_like 'writes correct content', 'y', '1'
      it_behaves_like 'writes correct content', 'n', '0'
    end

    context 'when KHULNASOFT_SIMULATE_SAAS is already present' do
      let(:env_runit_contents) { "export KHULNASOFT_SIMULATE_SAAS=1\n" }

      it 'does not write KHULNASOFT_SIMULATE_SAAS again' do
        expect(File).to receive(:open).with(env_runit_file.to_s, 'a')

        task.execute
      end
    end

    context 'when AI_GATEWAY_URL is already present' do
      let(:env_runit_contents) { "export AI_GATEWAY_URL=http://0.0.0.0:5052\n" }

      it 'writes KHULNASOFT_SIMULATE_SAAS but not AI_GATEWAY_URL' do
        expect(File).to receive(:open).with(env_runit_file.to_s, 'a')

        task.execute
      end
    end

    context 'when both KHULNASOFT_SIMULATE_SAAS and AI_GATEWAY_URL are present' do
      let(:env_runit_contents) { "export KHULNASOFT_SIMULATE_SAAS=1\nexport AI_GATEWAY_URL=http://0.0.0.0:5052" }

      it 'does not write anything' do
        expect(File).not_to receive(:open).with(env_runit_file.to_s, 'a')
        expect(File).not_to receive(:write).with(env_runit_file.to_s, anything)

        task.execute
      end
    end
  end

  context 'when user declines debug variables and hot reload' do
    let(:gateway_enabled) { true }

    before do
      allow(KDK::Output).to receive(:prompt).with('Enter your Anthropic API key').and_return('test_api_key')
      allow(KDK::Output).to receive(:prompt).with(/Do you want to set additional environment variables for debugging?/)
                                            .and_return('n')
      allow(KDK::Output).to receive(:prompt).with('Do you want to enable hot reload?[y/N]').and_return('n')
    end

    it 'skips setting debug variables and enabling hot reload' do
      expect(File).not_to receive(:write).with(env_file.to_s, /AIGW_LOGGING__LEVEL=debug/)
      expect(File).not_to receive(:write).with(env_file.to_s, /AIGW_FASTAPI__RELOAD=true/)

      task.execute
    end
  end

  context 'when .env file already exists' do
    let(:existing_env_content) { "EXISTING_VAR=value\n" }
    let(:gateway_enabled) { true }

    before do
      allow(File).to receive(:exist?).with(env_file.to_s).and_return(true)
      allow(File).to receive(:read).with(env_file.to_s).and_return(existing_env_content)
      allow(KDK::Output).to receive(:prompt).with('Enter your Anthropic API key').and_return('test_api_key')
    end

    it 'updates existing ANTHROPIC_API_KEY if present' do
      allow(File).to receive(:read).with(env_file.to_s).and_return("ANTHROPIC_API_KEY=old_key\n")
      expect(File).to receive(:write).with(env_file.to_s, "ANTHROPIC_API_KEY=test_api_key\n")

      task.execute
    end

    it 'appends ANTHROPIC_API_KEY if not present' do
      expect(File).to receive(:write).with(env_file.to_s, "EXISTING_VAR=value\nANTHROPIC_API_KEY=test_api_key\n")

      task.execute
    end

    it 'handles frozen strings correctly' do
      frozen_content = "EXISTING_VAR=value\n"
      allow(File).to receive(:read).with(env_file.to_s).and_return(frozen_content)
      expect(File).to receive(:write).with(env_file.to_s, "EXISTING_VAR=value\nANTHROPIC_API_KEY=test_api_key\n")

      expect { task.execute }.not_to raise_error
    end
  end
end
