# frozen_string_literal: true

RSpec.describe KDK::Diagnostic::PendingMigrations do
  include ShelloutHelper

  describe '#success?' do
    context 'when there are pending DB migrations' do
      it 'returns false' do
        stub_pending_migrations(false)

        expect(subject).not_to be_success
      end
    end

    context 'where there are no pending DB migrations' do
      it 'returns true' do
        stub_pending_migrations(true)

        expect(subject).to be_success
      end
    end
  end

  describe '#detail' do
    context 'when there are pending DB migrations' do
      it 'returns a message' do
        stub_pending_migrations(false)

        expect(subject.detail).to match(/There are pending database migrations/)
      end
    end

    context 'where there are no pending DB migrations' do
      it 'returns no message' do
        stub_pending_migrations(true)

        expect(subject.detail).to be_nil
      end
    end
  end

  def stub_pending_migrations(success)
    # Ensure fallback is used
    allow(KDK::Dependencies).to receive_messages(asdf_available?: false, mise_available?: false, homebrew_available?: false, linux_apt_available?: false)

    # Set up the fallback
    sh = kdk_shellout_double(run: '/usr/local/bin/psql')
    allow_kdk_shellout_command(%w[pg_config --bindir], chdir: KDK.root).and_return(sh)

    all_migrations = %w[1 2 3]

    sh = kdk_shellout_double(read_stdout: success ? all_migrations.join("\n") : all_migrations[..2].join("^\n"))
    allow(sh).to receive(:execute).with(display_output: false).and_return(sh)
    allow_kdk_shellout_command(get_psql_command('gitlabhq_development')).and_return(sh)
    allow_kdk_shellout_command(get_psql_command('gitlabhq_development_ci')).and_return(sh)

    schema_migrations_dir = "#{KDK.config.kdk_root.join('khulnasoft')}/db/schema_migrations"
    expect(Dir).to receive(:[]).with("#{schema_migrations_dir}/*").and_return(all_migrations.map { |m| "#{schema_migrations_dir}/#{m}" })
  end

  def get_psql_command(database_names)
    ["/usr/local/bin/psql/psql", "--host=/home/git/kdk/postgresql", "--port=5432", "--dbname=#{database_names}", "--no-align", "--tuples-only", "--command", "select version from schema_migrations"]
  end
end
