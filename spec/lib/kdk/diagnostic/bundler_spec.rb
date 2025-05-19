# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Bundler do
  include ShelloutHelper

  let(:khulnasoft_dir) { Pathname.new('/home/git/kdk/gitlab') }
  let(:force_ruby_platform) { false }

  before do
    settings = instance_double(Bundler::Settings)
    allow(settings).to receive(:[]).with(:force_ruby_platform).and_return(force_ruby_platform)
    allow(Bundler::Settings).to receive(:new).and_return(settings)
  end

  describe '#success?' do
    context "when gitlab doesn't have BUNDLE_PATH configured" do
      it 'returns true' do
        expect_bundle_path_not_set(khulnasoft_dir)

        expect(subject).to be_success
      end
    end

    context 'when force_ruby_platform is true' do
      let(:force_ruby_platform) { true }

      it 'returns false' do
        expect_bundle_path_not_set(khulnasoft_dir)
        expect(subject).not_to be_success
      end
    end
  end

  describe '#detail' do
    context "when gitlab doesn't have BUNDLE_PATH configured" do
      it 'returns no message' do
        expect_bundle_path_not_set(khulnasoft_dir)

        expect(subject.detail).to be_nil
      end
    end

    context 'when force_ruby_platform is true' do
      let(:force_ruby_platform) { true }

      it 'returns a message' do
        expect_bundle_path_not_set(khulnasoft_dir)
        expect(subject.detail).to include('The force_ruby_platform setting is enabled')
      end
    end
  end

  def expect_bundle_path_not_set(chdir)
    expect_shellout(chdir, stdout: 'You have not configured a value for `PATH`')
  end

  def expect_bundle_path_set(chdir)
    expect_shellout(chdir, stdout: 'Set for your local app (<path>/.bundle/config): "vendor/bundle"')
  end

  def expect_shellout(chdir, success: true, stdout: '', stderr: '')
    # rubocop:todo RSpec/VerifiedDoubles
    shellout = double('KDK::Shellout', try_run: nil, read_stdout: stdout, read_stderr: stderr, success?: success)
    # rubocop:enable RSpec/VerifiedDoubles
    expect_kdk_shellout_command('bundle config get PATH', chdir: chdir).and_return(shellout)
    expect(shellout).to receive(:execute).with(display_output: false).and_return(shellout)
  end
end
