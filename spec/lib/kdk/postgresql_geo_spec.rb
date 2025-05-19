# frozen_string_literal: true

RSpec.describe KDK::PostgresqlGeo do
  let(:yaml) { {} }
  let(:config) { KDK::Config.new(yaml: yaml) }

  subject { described_class.new(config) }

  before do
    stub_pg_bindir
  end

  describe '#use_tcp?' do
    context 'with host defined to a path' do
      let(:yaml) do
        {
          'postgresql' => {
            'geo' => {
              'host' => '/home/git/kdk/postgresql-geo'
            }
          }
        }
      end

      it 'returns false' do
        expect(subject).not_to be_use_tcp
      end
    end

    context 'with host defined to a hostname' do
      let(:yaml) do
        {
          'postgresql' => {
            'geo' => {
              'host' => 'localhost'
            }
          }
        }
      end

      it 'returns true' do
        expect(subject).to be_use_tcp
      end
    end
  end

  describe '#psql_cmd' do
    it 'calls pg_cmd' do
      expect(subject).to receive(:pg_cmd).with('--version', database: 'gitlabhq_geo_development').and_call_original

      subject.psql_cmd('--version')
    end
  end
end
