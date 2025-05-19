# frozen_string_literal: true

require 'simplecov-cobertura'
require 'tzinfo'
require 'tmpdir'
require 'tempfile'
require 'webmock/rspec'

SimpleCov.formatters = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::SimpleFormatter,
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::CoberturaFormatter
])
SimpleCov.start

require_relative '../lib/kdk_src'
require_relative '../lib/kdk'
require_relative '../lib/kdk/task_helpers'

require 'rake'
require "active_support/concern"

# Autoload helpers
autoload :MeasureHelper, 'helpers/measure_helper'
autoload :ShelloutHelper, 'helpers/shellout_helper'

# Load spec support code
Dir['spec/spec_support/**/*.rb'].each { |f| load f }

RSpec.configure do |config|
  # Allow running `:focus` examples locally, run everything on CI.
  config.filter_run_when_matching :focus unless ENV['CI']

  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.before(:suite) do
    temp_path.glob('*').each(&:rmtree)
  end

  config.before do |example|
    if example.metadata[:hide_stdout]
      allow(KDK::Output).to receive(:print)
      allow(KDK::Output).to receive(:puts)
    end

    if example.metadata[:hide_output]
      allow(KDK::Output).to receive(:print)
      allow(KDK::Output).to receive(:puts)
      allow(KDK::Output).to receive(:info)
      allow(KDK::Output).to receive(:warn)
      allow(KDK::Output).to receive(:error)
      allow(KDK::Output).to receive(:abort)
      allow(KDK::Output).to receive(:success)
    end

    unless example.metadata[:kdk_root]
      # isolate configs for the testing environment
      stub_const('KDK::Config::KDK_ROOT', Pathname.new('/home/git/kdk'))
      stub_const('KDK::Config::FILE', 'kdk.example.yml')

      kdk_root_tmp_path = temp_path

      real_tool_versions_file = Pathname.new('.tool-versions').expand_path
      allow(kdk_root_tmp_path).to receive(:join).and_call_original
      allow(kdk_root_tmp_path).to receive(:join).with('.tool-versions').and_return(real_tool_versions_file)
      allow(kdk_root_tmp_path).to receive(:glob).with('{.tool-versions,{*,*/*}/.tool-versions}').and_return([real_tool_versions_file])

      allow(KDK).to receive(:root).and_return(kdk_root_tmp_path)
      stub_kdk_yaml({})

      allow(Utils).to receive(:find_executable).and_return(nil)
    end

    unless example.metadata[:with_telemetry]
      allow(KDK::Telemetry).to receive(:with_telemetry).and_wrap_original do |_method, *_args, &block|
        block.call
      end
      allow(KDK::Telemetry).to receive(:capture_exception).with(anything)
      allow(KDK::Telemetry).to receive(:send_telemetry)
      allow(KDK::Telemetry).to receive(:flush_events)
    end
  end
end

def utc_now
  TZInfo::Timezone.get('UTC').now
end

def freeze_time(&blk)
  travel_to(&blk)
end

def travel_to(now = utc_now)
  # Copied from https://github.com/rails/rails/blob/v6.1.3/activesupport/lib/active_support/testing/time_helpers.rb#L163-L165
  #
  allow(Time).to receive(:now).and_return(now)
  allow(Date).to receive(:today).and_return(Date.jd(now.to_date.jd))
  allow(DateTime).to receive(:now).and_return(DateTime.jd(now.to_date.jd, now.hour, now.min, now.sec, Rational(now.utc_offset, 86400)))

  yield

  allow(Time).to receive(:now).and_call_original
  allow(Date).to receive(:today).and_call_original
  allow(DateTime).to receive(:now).and_call_original
end

def fixture_path
  KDK::SRC.join('spec').join('fixtures')
end

def temp_path
  KDK::SRC.join('tmp')
end

def stub_env(var, return_value)
  stub_const('ENV', ENV.to_hash.merge(var => return_value))
end

def stub_kdk_yaml(yaml)
  yaml = YAML.safe_load(yaml) if yaml.is_a?(String)
  config = KDK::Config.new(yaml: yaml)
  allow(KDK).to receive(:config) { config }
end

def stub_persisted_kdk_yaml(yaml)
  config = KDK::Config.load_from_file
  config.instance_variable_set(:@yaml, yaml)
  allow(KDK).to receive(:config) { config }
end

def stub_raw_kdk_yaml(raw_yaml)
  allow(File).to receive(:read).and_call_original
  allow(File).to receive(:read).with(KDK::Config::FILE).and_return(raw_yaml)
  allow(KDK).to receive(:config).and_call_original
end

def stub_pg_bindir
  allow_any_instance_of(KDK::PostgresqlUpgrader).to receive(:bin_path).and_return('/usr/local/bin')
end

def stub_tty(state)
  allow($stdin).to receive(:isatty).and_return(state)
end

def stub_no_color_env(res)
  stub_tty(true)

  # res needs to be of type String as we're simulating what's coming from
  # the shell command line.
  stub_env('NO_COLOR', res)
end

def stub_backup
  instance_spy(KDK::Backup).tap do |b|
    allow(KDK::Backup).to receive(:new).and_return(b)
  end
end

def stub_kdk_debug(state)
  kdk_settings = double('KDK::ConfigSettings', debug?: state, __debug?: state) # rubocop:todo RSpec/VerifiedDoubles
  allow_any_instance_of(KDK::Config).to receive(:kdk).and_return(kdk_settings)
end

def stub_prompt(response, message = 'Are you sure? [y/N]')
  allow(KDK::Output).to receive(:interactive?).and_return(true)
  allow(KDK::Output).to receive(:prompt).with(message).and_return(response)
end

def stub_tool_versions
  pg_version = instance_double(Asdf::ToolVersion, name: 'postgres', version: '16.8')
  pg_tool = instance_double(Asdf::Tool, name: pg_version.name, default_tool_version: pg_version)
  tools = {
    pg_version.name => pg_tool
  }

  allow_any_instance_of(Asdf::ToolVersions).to receive(:tool_versions).and_return(tools)
end

def stub_find_executable(name, path)
  allow(Utils).to receive(:find_executable).with(name).and_return(path)
end

def unstub_find_executable
  allow(Utils).to receive(:find_executable).and_call_original
end

def expect_no_error_report
  expect(KDK::Telemetry).not_to have_received(:capture_exception)
end

def create_dummy_executable(name)
  path = File.join(tmp_path, name)
  FileUtils.touch(path)
  File.chmod(0o755, path)

  path
end
