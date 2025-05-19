# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::RubyGems do
  include ShelloutHelper

  let(:allow_gem_not_installed) { nil }
  let(:bundle_check_ok) { nil }

  subject(:diagnostic) { described_class.new(allow_gem_not_installed: allow_gem_not_installed) }

  before do
    stub_bundle_check(bundle_check_ok)
    stub_const('KDK::Diagnostic::RubyGems::GEM_REQUIRE_MAPPING', { 'bad_gem' => 'actual_gem_name' })
    stub_const('KDK::Diagnostic::RubyGems::KHULNASOFT_GEMS_WITH_C_CODE_TO_CHECK', %w[bad_gem])
  end

  describe '#success?' do
    context 'when bundle check fails' do
      let(:bundle_check_ok) { false }

      it { is_expected.not_to be_success }
    end

    context 'when bundle check succeeds' do
      let(:bundle_check_ok) { true }

      before do
        stub_gem_installed('bad_gem', gem_installed)
      end

      context 'when bad_gem is not installed' do
        let(:gem_installed) { false }

        context 'and allow_gem_not_installed is false' do
          let(:allow_gem_not_installed) { false }

          it { is_expected.not_to be_success }
        end

        context 'and allow_gem_not_installed is true' do
          let(:allow_gem_not_installed) { true }

          it { is_expected.to be_success }
        end
      end

      context 'when bad_gem is installed' do
        let(:gem_installed) { true }

        before do
          stub_gem_loads_ok('bad_gem', gem_loads_ok)
        end

        context 'and bad_gem cannot be loaded' do
          let(:gem_loads_ok) { false }

          it { is_expected.not_to be_success }
        end

        context 'and bad_gem is loaded correctly' do
          let(:gem_loads_ok) { true }

          it { is_expected.to be_success }
        end
      end
    end
  end

  describe '#detail' do
    subject(:detail) { diagnostic.detail }

    context 'when bundle check fails' do
      let(:bundle_check_ok) { false }

      it { is_expected.to match(/There are Ruby gems missing that need to be installed./) }
    end

    context 'when bundle check succeeds' do
      let(:bundle_check_ok) { true }

      before do
        stub_gem_installed('bad_gem', gem_installed)
      end

      context 'when bad_gem is not installed' do
        let(:gem_installed) { false }

        context 'and allow_gem_not_installed is false' do
          let(:allow_gem_not_installed) { false }

          it { is_expected.to match(/bundle pristine bad_gem/) }
        end

        context 'and allow_gem_not_installed is true' do
          let(:allow_gem_not_installed) { true }

          it { is_expected.to be_nil }
        end
      end

      context 'when bad_gem is installed' do
        let(:gem_installed) { true }

        before do
          stub_gem_loads_ok('bad_gem', gem_loads_ok)
        end

        context 'and bad_gem cannot be loaded' do
          let(:gem_loads_ok) { false }

          it { is_expected.to match(/bundle pristine bad_gem/) }
        end

        context 'and bad_gem is loaded correctly' do
          let(:gem_loads_ok) { true }

          it { is_expected.to be_nil }
        end
      end
    end
  end

  def stub_bundle_check(success)
    stub_shellout("/home/git/kdk/support/bundle-exec bundle check", success)
  end

  def stub_gem_installed(name, success)
    stub_shellout("/home/git/kdk/support/bundle-exec gem list -i #{name}", success)
  end

  def stub_gem_loads_ok(name, success)
    gem_name = KDK::Diagnostic::RubyGems::GEM_REQUIRE_MAPPING[name]
    stub_shellout("/home/git/kdk/support/bundle-exec ruby -r #{gem_name} -e 'nil'", success)
  end

  def stub_shellout(cmd, success)
    shellout_double = kdk_shellout_double(success?: success)

    allow_kdk_shellout_command(cmd, chdir: '/home/git/kdk/gitlab').and_return(shellout_double)
    allow(shellout_double).to receive(:execute).with(display_output: false, display_error: false).and_return(shellout_double)

    shellout_double
  end
end
