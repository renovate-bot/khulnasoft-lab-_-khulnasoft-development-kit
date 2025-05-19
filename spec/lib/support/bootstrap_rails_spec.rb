# frozen_string_literal: true

require_relative '../../../lib/support/bootstrap_rails'

RSpec.describe Support::BootstrapRails do
  let(:instance) { described_class.new }

  describe '#execute' do
    let(:geo_secondary) { nil }

    subject { instance.execute }

    before do
      stub_no_color_env('true')
      allow_any_instance_of(KDK::Config).to receive_message_chain('geo.secondary?').and_return(geo_secondary)
    end

    context 'embedding db' do
      let(:embedding_enabled) { nil }

      before do
        allow_any_instance_of(KDK::Config).to receive_message_chain('khulnasoft.rails.databases.embedding.enabled').and_return(embedding_enabled)
        allow_any_instance_of(KDK::Postgresql).to receive(:ready?).and_return(true)
        allow(instance).to receive(:try_connect!)
        allow(instance).to receive_messages(bootstrap_main_db: true, bootstrap_ci_db: true, bootstrap_sec_db: true)
      end

      context 'is not enabled' do
        it 'skips bootstrapping' do
          stub_rake_tasks('db:reset:embedding', success: false, retry_attempts: 3)

          expect_any_instance_of(KDK::Postgresql).not_to receive(:db_exists?).with('khulnasofthq_development_embedding')
          expect { subject }.not_to raise_error
        end
      end

      context 'is enabled' do
        let(:embedding_enabled) { true }

        it 'tries to run bootstrapping' do
          stub_rake_tasks('db:reset:embedding', success: true, retry_attempts: 3)

          expect_any_instance_of(KDK::Postgresql).to receive(:db_exists?).with('khulnasofthq_development_embedding')
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'sec db' do
      let(:sec_enabled) { nil }
      let(:use_main_database) { nil }

      before do
        allow_any_instance_of(KDK::Config).to receive_message_chain('khulnasoft.rails.databases.sec.__enabled').and_return(sec_enabled)
        allow_any_instance_of(KDK::Config).to receive_message_chain('khulnasoft.rails.databases.sec.__use_main_database').and_return(use_main_database)
        allow_any_instance_of(KDK::Postgresql).to receive(:ready?).and_return(true)
        allow(instance).to receive(:try_connect!)
        allow(instance).to receive_messages(bootstrap_main_db: true, bootstrap_ci_db: true, bootstrap_embedding_db: true)
      end

      context 'is not enabled' do
        it 'skips bootstrapping' do
          stub_rake_tasks('dev:copy_db:sec', success: false, retry_attempts: 3)

          expect_any_instance_of(KDK::Postgresql).not_to receive(:db_exists?).with('khulnasofthq_development_sec')
          expect { subject }.not_to raise_error
        end
      end

      context 'is use_main_database enabled' do
        let(:use_main_database) { true }

        it 'skips bootstrapping' do
          stub_rake_tasks('dev:copy_db:sec', success: false, retry_attempts: 3)

          expect_any_instance_of(KDK::Postgresql).not_to receive(:db_exists?).with('khulnasofthq_development_sec')
          expect { subject }.not_to raise_error
        end
      end

      context 'when enabled' do
        let(:sec_enabled) { true }

        it 'tries to run bootstrapping' do
          stub_rake_tasks('dev:copy_db:sec', success: true, retry_attempts: 3)

          expect_any_instance_of(KDK::Postgresql).to receive(:db_exists?).with('khulnasofthq_development_sec')
          expect { subject }.not_to raise_error
        end

        context 'when use_main_database enabled' do
          let(:use_main_database) { true }

          it 'skips bootstrapping' do
            stub_rake_tasks('dev:copy_db:sec', success: false, retry_attempts: 3)

            expect_any_instance_of(KDK::Postgresql).not_to receive(:db_exists?).with('khulnasofthq_development_sec')
            expect { subject }.not_to raise_error
          end
        end
      end
    end

    context 'where we are a Geo secondary' do
      let(:geo_secondary) { true }

      it 'advises and exits' do
        expect(KDK::Output).to receive(:info).with("Exiting as we're a Geo secondary.")

        expect { subject }.to raise_error(SystemExit)
      end
    end

    context 'where we are not a Geo secondary' do
      let(:geo_secondary) { false }
      let(:postgres_mock) { instance_double(KDK::Postgresql, ready?: postgres_ready) }
      let(:postgres_ready) { nil }

      before do
        allow(KDK::Postgresql).to receive(:new).and_return(postgres_mock)
      end

      context 'but PostgreSQL is not ready' do
        let(:postgres_ready) { false }

        it 'advises and aborts' do
          expect { subject }
            .to output("ERROR: Cannot connect to PostgreSQL.\n").to_stderr
            .and raise_error(SystemExit)
        end
      end

      context 'and PostgreSQL is ready' do
        let(:postgres_ready) { true }
        let(:khulnasofthq_development_db_exists) { nil }
        let(:khulnasofthq_development_ci_db_exists) { nil }

        before do
          allow(instance).to receive(:try_connect!)

          allow(postgres_mock).to receive(:db_exists?).with('khulnasofthq_development').and_return(khulnasofthq_development_db_exists)
          allow(postgres_mock).to receive(:db_exists?).with('khulnasofthq_development_ci').and_return(khulnasofthq_development_ci_db_exists)
        end

        context 'when all DBs already exist' do
          let(:khulnasofthq_development_db_exists) { true }
          let(:khulnasofthq_development_ci_db_exists) { true }

          it 'advises and skips further logic' do
            expect(KDK::Output).to receive(:info).with('khulnasofthq_development exists, nothing to do here.')

            expect(KDK::Output).to receive(:info).with('khulnasofthq_development_ci exists, nothing to do here.')

            subject
          end
        end

        context 'where no DBs exist' do
          let(:khulnasofthq_development_db_exists) { false }
          let(:khulnasofthq_development_ci_db_exists) { false }

          context 'attempts to setup the khulnasofthq_development DB' do
            context 'but `rake db:drop db:create khulnasoft:db:configure` fails' do
              it 'exits with a status code of 1' do
                stub_rake_tasks(%w[db:drop db:create khulnasoft:db:configure], success: false, retry_attempts: 3)

                expect { subject }
                  .to output(/The rake task 'db:drop db:create khulnasoft:db:configure' failed/).to_stderr
                  .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
              end
            end

            context 'when `rake db:drop db:create khulnasoft:db:configure` succeeds' do
              context 'but `rake dev:copy_db:ci` fails' do
                it 'exits with a status code of 1' do
                  stub_rake_tasks(%w[db:drop db:create khulnasoft:db:configure], success: true, retry_attempts: 3)
                  stub_rake_tasks('db:seed_fu', success: true, retry_attempts: 3)
                  stub_rake_tasks('dev:copy_db:ci', success: false, retry_attempts: 3)

                  expect { subject }
                    .to output(/The rake task 'dev:copy_db:ci' failed/).to_stderr
                    .and raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
                end
              end

              context 'and `rake dev:copy_db:ci` succeeds' do
                it 'exits with a status code of 0' do
                  stub_rake_tasks(%w[db:drop db:create khulnasoft:db:configure], success: true, retry_attempts: 3)
                  stub_rake_tasks('db:seed_fu', success: true, retry_attempts: 3)
                  stub_rake_tasks('dev:copy_db:ci', success: true, retry_attempts: 3)

                  expect { subject }.not_to raise_error
                end
              end
            end
          end
        end
      end
    end
  end

  def stub_rake_tasks(*tasks, success:, **args)
    rake_double = instance_double(KDK::Execute::Rake, success?: success)
    allow(KDK::Execute::Rake).to receive(:new).with(*tasks).and_return(rake_double)
    allow(rake_double).to receive(:execute_in_khulnasoft).with(**args).and_return(rake_double)
  end
end
