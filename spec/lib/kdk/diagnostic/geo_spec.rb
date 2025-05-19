# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::Geo do
  subject(:geo_diagnostic) { described_class.new }

  let(:database_yml_file) { '/home/git/kdk/khulnasoft/config/database.yml' }

  let(:default_content) do
    <<-CONTENT
      development:
        main:
          adapter: postgresql
          encoding: unicode
          database: gitlabhq_development
          username: postgres
          password: "secure password"
          host: localhost
          variables:
            statement_timeout: 15s
    CONTENT
  end

  let(:geo_content) do
    <<-CONTENT
      development:
        main:
          adapter: postgresql
          encoding: unicode
          database: gitlabhq_development
          username: postgres
          password: "secure password"
          host: localhost
          variables:
            statement_timeout: 15s

        geo:
          adapter: postgresql
          encoding: unicode
          database: gitlabhq_geo_development
          username: postgres
          password: "secure password"
          host: localhost
          variables:
            statement_timeout: 15s
    CONTENT
  end

  shared_examples 'with Geo diagnostic success' do |geo_enabled, expected_result, database_settings = nil|
    it "returns #{expected_result}" do
      stub_geo_enabled(geo_enabled)
      stub_database_yml_content(database_settings) if database_settings

      expect(geo_diagnostic.success?).to eq(expected_result)
    end
  end

  describe '#success?' do
    context 'when geo.enabled is false' do
      before do
        stub_geo_enabled(false)
      end

      context 'and Geo database does not exist' do
        include_examples 'with Geo diagnostic success', false, true
      end

      context 'and Geo database exists' do
        before do
          stub_database_yml_content(geo_content)
        end

        it 'returns false' do
          expect(geo_diagnostic.success?).to be(false)
        end
      end
    end

    context 'when geo.enabled is true and geo.secondary is true' do
      before do
        stub_geo_enabled(true)
        stub_geo_secondary
      end

      context 'and Geo database does not exist' do
        include_examples 'with Geo diagnostic success', true, false
      end

      context 'and Geo database exists' do
        before do
          stub_database_yml_content(geo_content)
        end

        it 'returns true' do
          expect(geo_diagnostic.success?).to be(true)
        end
      end
    end

    context 'when geo.enabled is true and geo.secondary is false' do
      before do
        stub_geo_enabled(true)
        stub_geo_primary
      end

      context 'and Geo database does not exist' do
        include_examples 'with Geo diagnostic success', true, true
      end

      context 'and Geo database exists' do
        before do
          stub_database_yml_content(geo_content)
        end

        it 'returns false' do
          expect(geo_diagnostic.success?).to be(false)
        end
      end
    end
  end

  describe '#detail' do
    let(:success) { nil }

    before do
      allow(geo_diagnostic).to receive(:success?).and_return(success)
    end

    context 'when #success? returns true' do
      let(:success) { true }

      it 'returns nil' do
        expect(geo_diagnostic.detail).to be_nil
      end
    end

    context 'when #success? returns false' do
      context 'when geo.enabled is false and Geo database exists' do
        let(:success) { false }

        before do
          stub_geo_enabled(false)
          stub_database_yml_content(geo_content)
        end

        it 'returns a message advising how to detail with the situation' do
          expected_detail = <<~MESSAGE
            There is a mismatch in your Geo configuration.

            Geo is disabled in KDK, but `/home/git/kdk/khulnasoft/config/database.yml` contains geo database.

            Please run `kdk reconfigure` to apply settings in kdk.yml.
            For more details, please refer to https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/main/doc/howto/geo.md.
          MESSAGE

          expect(geo_diagnostic.detail).to eq(expected_detail)
        end
      end

      context 'when geo.enabled is true and geo.secondary is true and Geo database does not exist' do
        let(:success) { false }

        before do
          stub_geo_enabled(true)
          stub_geo_secondary
          stub_database_yml_content(default_content)
        end

        it 'returns a message advising how to detail with the situation' do
          expected_detail = <<~MESSAGE
            There is a mismatch in your Geo configuration.

            Geo is enabled in KDK as a secondary, but `/home/git/kdk/khulnasoft/config/database.yml` does not contain geo database.

            Please run `kdk reconfigure` to apply settings in kdk.yml.
            For more details, please refer to https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/main/doc/howto/geo.md.
          MESSAGE

          expect(geo_diagnostic.detail).to eq(expected_detail)
        end
      end

      context 'when geo.enabled is true and geo.secondary is false and Geo database exists' do
        let(:success) { false }

        before do
          stub_geo_enabled(true)
          stub_geo_primary
          stub_database_yml_content(geo_content)
        end

        it 'returns a message advising how to detail with the situation' do
          expected_detail = <<~MESSAGE
            There is a mismatch in your Geo configuration.

            Geo is enabled in KDK, but not as a secondary node, so `/home/git/kdk/khulnasoft/config/database.yml` should not contain geo database.

            Please run `kdk reconfigure` to apply settings in kdk.yml.
            For more details, please refer to https://github.com/khulnasoft-lab/khulnasoft-development-kit/blob/main/doc/howto/geo.md.
          MESSAGE

          expect(geo_diagnostic.detail).to eq(expected_detail)
        end
      end
    end
  end

  def stub_database_yml_content(content)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(database_yml_file).and_return(true)

    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(database_yml_file).and_return(content)
  end

  def stub_geo_enabled(enabled)
    allow_any_instance_of(KDK::Config).to receive_message_chain('geo.enabled').and_return(enabled)
  end

  def stub_geo_primary
    allow_any_instance_of(KDK::Config).to receive_message_chain('geo.secondary').and_return(nil)
  end

  def stub_geo_secondary
    allow_any_instance_of(KDK::Config).to receive_message_chain('geo.secondary').and_return(true)
  end
end
