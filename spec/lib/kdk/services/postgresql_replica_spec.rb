# frozen_string_literal: true

RSpec.describe KDK::Services::PostgresqlReplica do
  before do
    stub_pg_bindir
  end

  describe '#name' do
    it 'return postgresql-replica' do
      expect(subject.name).to eq('postgresql-replica')
    end
  end

  describe '#command' do
    it 'returns the necessary command to run PostgreSQL replica' do
      expect(subject.command).to eq(
        %W[
          support/postgresql-signal-wrapper
          /usr/local/bin/postgres
          -D /home/git/kdk/postgresql-replica/data
          -k /home/git/kdk/postgresql-replica -h ''
          -c max_connections=100
        ].join(' ')
      )
    end
  end

  describe '#enabled?' do
    it 'is disable by default' do
      expect(subject.enabled?).to be(false)
    end
  end
end
