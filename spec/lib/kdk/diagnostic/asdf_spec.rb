# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Asdf do
  let(:opt_out) { false }

  before do
    allow(KDK.config).to receive_message_chain(:asdf, :opt_out?).and_return(opt_out)
  end

  describe '#success?' do
    let(:unnecessary_software_to_uninstall) { nil }

    before do
      asdf_tool_versions = stub_asdf_tool_versions
      allow(asdf_tool_versions).to receive(:unnecessary_software_to_uninstall?).and_return(unnecessary_software_to_uninstall)
    end

    context 'when asdf.opt_out? is true' do
      let(:opt_out) { true }

      it 'returns true' do
        expect(subject).to be_success
      end
    end

    context 'when asdf.opt_out? is false' do
      let(:opt_out) { false }

      context 'when there is unnecessary software to_uninstall' do
        let(:unnecessary_software_to_uninstall) { true }

        it 'returns false' do
          expect(subject).not_to be_success
        end
      end

      context "when there isn't unnecessary software to_uninstall" do
        let(:unnecessary_software_to_uninstall) { false }

        it 'returns true' do
          expect(subject).to be_success
        end
      end
    end
  end

  describe '#detail' do
    let(:unnecessary_software_to_uninstall) { nil }
    let(:asdf_tool_versions) { stub_asdf_tool_versions }

    before do
      allow(asdf_tool_versions).to receive(:unnecessary_software_to_uninstall?).and_return(unnecessary_software_to_uninstall)
    end

    context 'when there is unnecessary software to_uninstall' do
      let(:unnecessary_software_to_uninstall) { true }

      it 'returns a message' do
        allow(asdf_tool_versions).to receive(:unnecessary_installed_versions_of_software).and_return('golang' => { '1.17.1' => 'ToolVersion' })

        expect(subject.detail).to match(/^You have the following software installed using asdf.+golang 1.17.1.*If you know other projects don't need them.*rake asdf:uninstall_unnecessary_software$/m)
      end
    end

    context "when there isn't unnecessary software to_uninstall" do
      let(:unnecessary_software_to_uninstall) { false }

      it 'returns no message' do
        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_asdf_tool_versions
    asdf_tool_versions = instance_double(Asdf::ToolVersions)
    allow(Asdf::ToolVersions).to receive(:new).and_return(asdf_tool_versions)
    asdf_tool_versions
  end
end
