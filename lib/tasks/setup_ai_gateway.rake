# frozen_string_literal: true

require_relative '../kdk'

AI_GATEWAY_ENV_FILE = File.join(KDK.root, 'gitlab-ai-gateway', '.env')
ENV_RUNIT_FILE = File.join(KDK.root, 'env.runit')
LOG_FILE = File.join(KDK.root, 'log/gitlab-ai-gateway/gateway_debug.log')
DEBUG_VARS = {
  'AIGW_LOGGING__LEVEL' => 'debug',
  'AIGW_LOGGING__FORMAT_JSON' => 'false',
  'AIGW_LOGGING__TO_FILE' => LOG_FILE
}.freeze

def update_env_file(env_file, key, value)
  env_contents = File.exist?(env_file) ? File.read(env_file).dup : ''
  env_contents = env_contents.strip

  if env_contents.match?(/^#{key}=/)
    env_contents.sub!(/^#{key}=.*/, "#{key}=#{value}")
  else
    env_contents << "\n" unless env_contents.empty?
    env_contents << "#{key}=#{value}"
  end

  File.write(env_file, "#{env_contents}\n")
end

desc 'Set up KhulnaSoft AI Gateway'
task :setup_ai_gateway do
  KDK::Output.puts 'Setting up KhulnaSoft AI Gateway...'
  anthropic_key = KDK::Output.prompt('Enter your Anthropic API key')
  enable_debug = KDK::Output.prompt('Do you want to set additional environment variables for debugging? [y/N]')
  saas_mode_enabled = KDK::Output.prompt('Do you want to enable Duo Features in SaaS (KhulnaSoft.com) Mode? [y/N]')
  enable_hot_reload = KDK::Output.prompt('Do you want to enable hot reload?[y/N]')

  KDK::Output.puts 'Enabling KhulnaSoft AI Gateway in KDK config...'
  KDK.config.bury!('khulnasoft_ai_gateway.enabled', true)
  KDK.config.save_yaml!

  KDK::Output.puts 'Updating KDK...'
  success = KDK::Command::Update.new.run

  unless success
    KDK::Output.error("Updating KDK failed. Make sure `kdk update` command succeeds in your terminal.")
    next
  end

  unless File.file?(AI_GATEWAY_ENV_FILE)
    KDK::Output.error("AI Gateway env file was not found at #{AI_GATEWAY_ENV_FILE}. Retrying `rake setup_ai_gateway` command might resolve the issue.")
    next
  end

  KDK::Output.puts 'Setting up Anthropic API key...'
  update_env_file(AI_GATEWAY_ENV_FILE, 'ANTHROPIC_API_KEY', anthropic_key)
  update_env_file(AI_GATEWAY_ENV_FILE, 'AIGW_AUTH__BYPASS_EXTERNAL', 'true')

  KDK::Output.puts 'Setting up Google Cloud...'
  KDK.make('gitlab-ai-gateway-gcloud-setup')

  if enable_debug.match?(/\Ay(?:es)*\z/i)
    DEBUG_VARS.each do |key, value|
      update_env_file(AI_GATEWAY_ENV_FILE, key, value)
    end

    KDK::Output.puts 'Debug variables have been set.'
  end

  if enable_hot_reload.match?(/\Ay(?:es)*\z/i)
    update_env_file(AI_GATEWAY_ENV_FILE, 'AIGW_FASTAPI__RELOAD', 'true')
    KDK::Output.puts 'Hot reload has been enabled.'
  end

  env_runit_contents = File.exist?(ENV_RUNIT_FILE) ? File.read(ENV_RUNIT_FILE) : ''

  unless env_runit_contents.include?('export KHULNASOFT_SIMULATE_SAAS=') && env_runit_contents.include?('export AI_GATEWAY_URL=http://0.0.0.0:5052')
    File.open(ENV_RUNIT_FILE, 'a') do |f|
      new_content = []
      new_content << "\n# Added by KhulnaSoft AI Gateway setup" unless env_runit_contents.empty?

      unless env_runit_contents.include?('export KHULNASOFT_SIMULATE_SAAS')
        new_content << if saas_mode_enabled.match?(/\Ay(?:es)*\z/i)
                         'export KHULNASOFT_SIMULATE_SAAS=1'
                       else
                         'export KHULNASOFT_SIMULATE_SAAS=0'
                       end
      end

      env_runit_contents.include?('export AI_GATEWAY_URL=http://127.0.0.1:5052') ||
        (new_content << 'export AI_GATEWAY_URL=http://127.0.0.1:5052')

      f.write("#{new_content.join("\n")}\n")
      KDK::Output.puts "Updated env.runit file with #{new_content}"
    end
  end

  KDK::Output.puts 'Restarting services...'
  KDK::Command::Restart.new.run

  KDK::Output.puts 'KDK AI Gateway setup complete'
  KDK::Output.puts "Access AI Gateway docs at the url listed in 'kdk status'"
  KDK::Output.puts 'For more information, see https://docs.gitlab.com/ee/development/ai_features/index.html'

  KDK::Output.success('Done')
end
