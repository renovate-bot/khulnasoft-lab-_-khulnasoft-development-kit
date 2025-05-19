# frozen_string_literal: true

RSpec.describe Asdf::ToolVersions do
  let(:software_name) { 'golang' }
  let(:wanted_software_versions) { ['1.17.2', '1.21.9'] }
  let(:unnecessary_software_version) { '1.17.1' }
  let(:unnecessary_software_tool_version) { Asdf::ToolVersion.new(software_name, unnecessary_software_version) }
  let(:tmp_dir_we_pretend_exists) { '/tmp/dir/that/we/pretend/exists/asdf' }

  subject { described_class.new }

  describe '#default_tool_version_for' do
    context 'postgres' do
      it 'returns instance of Asdf::ToolVersion' do
        tool_version = subject.default_tool_version_for('postgres')

        expect(tool_version).to be_instance_of(Asdf::ToolVersion)
        expect(tool_version.version).to eq('16.8')
      end
    end
  end

  describe '#default_version_for' do
    context 'when a .tool-versions file is in the root directory' do
      it 'returns postgres version 16.8' do
        expect(subject.default_version_for('postgres')).to eq('16.8')
      end
    end

    context 'when a .tool-versions file is one level deep' do
      let(:first_level_file) { KDK.root.join('level1/.tool-versions') }

      before do
        allow(KDK.root).to receive(:glob).with('{.tool-versions,{*,*/*}/.tool-versions}').and_return([first_level_file])
        allow(File).to receive(:readlines).with(first_level_file).and_return(['gitleaks 8.18.2'])
      end

      it 'retrieves the correct version' do
        expect(subject.default_version_for('gitleaks')).to eq('8.18.2')
      end
    end

    context 'when a .tool-versions file is more than one level deep' do
      let(:second_level_file) { KDK.root.join('level1/level2/.tool-versions') }

      before do
        allow(KDK.root).to receive(:glob).with('{.tool-versions,{*,*/*}/.tool-versions}').and_return([])
        allow(File).to receive(:readlines).with(second_level_file).and_return(['nonexistent 1.2.3'])
      end

      it 'does not retrieve versions' do
        expect(subject.default_version_for('nonexistent')).to be_nil
      end
    end
  end

  describe '#unnecessary_software_to_uninstall?' do
    before do
      stub_asdf_data_installs_dir(tmp_dir_we_pretend_exists, exist: true)
    end

    context "when there isn't any software to uninstall" do
      it 'returns false' do
        stub_no_unnecessary_installed_software

        expect(subject.unnecessary_software_to_uninstall?).to be_falsey
      end
    end

    context 'when there is software to uninstall' do
      it 'returns true' do
        stub_some_unnecessary_installed_software

        expect(subject.unnecessary_software_to_uninstall?).to be_truthy
      end
    end
  end

  describe '#unnecessary_installed_versions_of_software' do
    before do
      stub_some_unnecessary_installed_software
    end

    it 'returns a Hash of software and versions that can be uninstalled' do
      expect(subject.unnecessary_installed_versions_of_software).to be_a(Hash)
    end

    it 'contains golang 1.17.1' do
      unnecessary_installed_versions_of_software = subject.unnecessary_installed_versions_of_software

      expect(unnecessary_installed_versions_of_software).to include(software_name => { unnecessary_software_version => unnecessary_software_tool_version })
    end
  end

  describe '#uninstall_unnecessary_software!' do
    context 'when asdf installs directory does not exist (asdf not in use)' do
      it 'informs and returns true' do
        non_existent_asdf_dir = '/tmp/dir/that/doesnt/exist/asdf'
        stub_asdf_data_installs_dir(non_existent_asdf_dir, exist: false)

        expect(KDK::Output).to receive(:info).with("Skipping because '#{non_existent_asdf_dir}/installs' does not exist.")

        expect(subject.uninstall_unnecessary_software!).to be_truthy
      end
    end

    context 'when asdf installs directory does exist' do
      before do
        stub_asdf_data_installs_dir(tmp_dir_we_pretend_exists, exist: true)
      end

      context 'when asdf.opt_out is set to true' do
        it 'informs and returns true' do
          allow_any_instance_of(KDK::Config).to receive_message_chain('asdf.opt_out?').and_return(true)

          expect(KDK::Output).to receive(:info).with('Skipping because asdf.opt_out is set to true.')

          expect(subject.uninstall_unnecessary_software!).to be_truthy
        end
      end

      context 'when there is no software to uninstall' do
        it 'informs and returns true' do
          stub_no_unnecessary_installed_software

          expect(KDK::Output).to receive(:info).with('No unnecessary asdf software to uninstall.')

          expect(subject.uninstall_unnecessary_software!).to be_truthy
        end
      end

      context 'when there is software to uninstall' do
        before do
          stub_some_unnecessary_installed_software
        end

        context 'when prompted' do
          context 'and the user accepts' do
            context 'but an unhandled exception occurs' do
              it 'aborts with exception', :hide_output do
                stub_prompt('y')

                expect_warn_and_puts
                expect(unnecessary_software_tool_version).to receive(:uninstall!).and_raise(StandardError)

                expect { subject.uninstall_unnecessary_software! }.to raise_error(StandardError)
              end
            end

            context 'but the uninstall command returns a non-zero exit code' do
              it 'return false' do
                stub_prompt('y')

                expect_warn_and_puts
                expect(unnecessary_software_tool_version).to receive(:uninstall!).and_raise(Asdf::ToolVersion::UninstallFailedError)
                expect_uninstall_failure

                expect(subject.uninstall_unnecessary_software!).to be_falsey
              end
            end
          end

          context 'but the user does not accept' do
            it 'does not uninstall and returns true' do
              stub_prompt('n')

              expect_warn_and_puts
              expect(unnecessary_software_tool_version).not_to receive(:uninstall!)

              expect(subject.uninstall_unnecessary_software!).to be_truthy
            end
          end

          context 'when software succeeds in uninstalling' do
            context 'and the user accepts' do
              context 'by setting KDK_ASDF_UNINSTALL_UNNECESSARY_SOFTWARE_CONFIRM to true' do
                it 'uninstalls returns true' do
                  stub_env('KDK_ASDF_UNINSTALL_UNNECESSARY_SOFTWARE_CONFIRM', 'true')

                  expect_warn_and_puts
                  expect(unnecessary_software_tool_version).to receive(:uninstall!).and_return(true)
                  expect_uninstall_success

                  expect(subject.uninstall_unnecessary_software!).to be_truthy
                end
              end

              context 'via a direct response' do
                it 'uninstalls returns true' do
                  stub_prompt('y')

                  expect_warn_and_puts
                  expect(unnecessary_software_tool_version).to receive(:uninstall!).and_return(true)
                  expect_uninstall_success

                  expect(subject.uninstall_unnecessary_software!).to be_truthy
                end
              end
            end
          end
        end

        context 'when asked to not prompt' do
          context 'when software succeeds in uninstalling' do
            it 'returns true' do
              expect(KDK::Output).not_to receive(:warn).with('About to uninstall the following asdf software:')
              expect(KDK::Output).not_to receive(:puts).with("#{software_name} #{unnecessary_software_version}")
              expect(KDK::Output).not_to receive(:prompt).with('Are you sure? [y/N]')

              expect(unnecessary_software_tool_version).to receive(:uninstall!).and_return(true)
              expect_uninstall_success

              expect(subject.uninstall_unnecessary_software!(prompt: false)).to be_truthy
            end
          end
        end
      end
    end

    def expect_warn_and_puts
      expect(KDK::Output).to receive(:warn).with('About to uninstall the following asdf software:').ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
      expect(KDK::Output).to receive(:puts).with("#{software_name} #{unnecessary_software_version}").ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
    end

    def expect_uninstall_info
      expect(KDK::Output).to receive(:print).with("Uninstalling #{software_name} ").ordered
      expect(KDK::Output).to receive(:print).with(unnecessary_software_version).ordered
    end

    def expect_uninstall_success
      expect_uninstall_info
      expect(KDK::Output).to receive(:puts).with(" #{KDK::Output.icon(:success)}").ordered
    end

    def expect_uninstall_failure
      expect_uninstall_info
      expect(KDK::Output).to receive(:puts).with(" #{KDK::Output.icon(:error)}").ordered
      expect(KDK::Output).to receive(:puts).with(stderr: true).ordered
      expect(KDK::Output).to receive(:warn).with("Failed to uninstall the following:\n\n").ordered
      expect(KDK::Output).to receive(:puts).with("#{software_name} #{unnecessary_software_version}").ordered
    end
  end

  def stub_asdf_data_installs_dir(dir, exist:)
    stub_env('HOME', '/home/kdk')
    stub_env('ASDF_DATA_DIR', dir)

    asdf_data_installs_dir_double = instance_double(Pathname, exist?: exist, to_s: "#{dir}/installs")
    asdf_data_dir_double = instance_double(Pathname, join: asdf_data_installs_dir_double)
    allow(Pathname).to receive(:new).and_call_original
    allow(Pathname).to receive(:new).with(dir).and_return(asdf_data_dir_double)
  end

  def stub_no_unnecessary_installed_software
    stub_software(wanted_versions: wanted_software_versions, installed_versions: wanted_software_versions)
  end

  def stub_some_unnecessary_installed_software
    stub_software(wanted_versions: wanted_software_versions, installed_versions: [unnecessary_software_version])
  end

  def stub_software(wanted_versions:, installed_versions:)
    allow(Asdf::ToolVersion).to receive(:new).and_call_original

    allow(subject).to receive(:raw_tool_versions_lines).and_return(wanted_versions.map { |version| "#{software_name} #{version}" })
    allow(subject).to receive(:asdf_install_dirs_for).with(software_name).and_return(installed_versions.map { |version| Pathname.new("/tmp/.asdf_fake/installs/#{software_name}/#{version}") })

    (wanted_versions + installed_versions).each do |version|
      allow(Asdf::ToolVersion).to receive(:new).with(software_name, version).and_return(Asdf::ToolVersion.new(software_name, version))
    end
  end
end
