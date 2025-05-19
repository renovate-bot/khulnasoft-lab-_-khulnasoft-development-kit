# frozen_string_literal: true

RSpec.describe KDK::Services::Postgresql do
  before do
    stub_pg_bindir
  end

  describe '#name' do
    it 'return postgresql' do
      expect(subject.name).to eq('postgresql')
    end
  end

  describe '#command' do
    let(:expected_args) do
      %W[
        support/postgresql-signal-wrapper
        /usr/local/bin/postgres
        -D /home/git/kdk/postgresql/data
        -k /home/git/kdk/postgresql -h ''
        -c max_connections=100
      ]
    end

    it 'returns the necessary command to run PostgreSQL' do
      expect(subject.command).to eq(expected_args.join(' '))
    end
  end

  describe '#enabled?' do
    it 'is enabled by default' do
      expect(subject).to be_enabled
    end
  end

  describe '#postgresql_max_connections' do
    shared_examples 'postgresql_max_connections' do
      let(:expected_args) do
        %W[
          support/postgresql-signal-wrapper
          /usr/local/bin/postgres
          -D /home/git/kdk/postgresql/data
          -k /home/git/kdk/postgresql -h ''
          -c max_connections=#{expected_max_connections}
        ]
      end

      before do
        stub_kdk_yaml(config)
      end

      it 'sets the max_connections configuration' do
        expect(subject.command).to eq(expected_args.join(' '))
      end
    end

    context 'with default value' do
      let(:config) { {} }
      let(:expected_max_connections) { 100 }

      it_behaves_like 'postgresql_max_connections'
    end

    context 'with configured value' do
      let(:config) do
        {
          'postgresql' => {
            'max_connections' => 10
          }
        }
      end

      let(:expected_max_connections) { 10 }

      it_behaves_like 'postgresql_max_connections'
    end
  end
end
