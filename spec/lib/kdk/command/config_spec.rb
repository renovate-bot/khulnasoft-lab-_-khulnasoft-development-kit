# frozen_string_literal: true

RSpec.describe KDK::Command::Config do
  before do
    stub_persisted_kdk_yaml({})
    stub_pg_bindir
    stub_no_color_env('true')
    stub_backup
  end

  describe '.validate_config?' do
    subject { described_class.validate_config? }

    it { is_expected.to be(false) }
  end

  context 'with no extra argument' do
    it 'aborts execution and returns usage instructions' do
      expect { subject.run([]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
    end
  end

  context 'with invalid extra arguments' do
    it 'aborts execution and returns usage instructions' do
      expect { subject.run(%w[non-existent-command]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
    end
  end

  context 'get' do
    context 'with a missing key' do
      it 'aborts execution and returns an error' do
        expect { subject.run(%w[get]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr

        expect_no_error_report
      end
    end

    context 'with valid extra arguments' do
      it 'returns values retrieved from configuration store' do
        expect { subject.run(%w[get port]) }.to output(/3000/).to_stdout
      end

      context 'with nonexistent configuration keys' do
        it 'aborts execution and returns an error' do
          expect { subject.run(%w[get unknownkey]) }.to raise_error(SystemExit).and output(/Cannot get config for/).to_stderr

          expect_no_error_report
        end
      end

      context 'accessing an array' do
        it 'returns all values serialized as YAML' do
          expect { subject.run(%w[get praefect.__nodes]) }.to output(%r{config_file: gitaly/gitaly-0.praefect.toml}).to_stdout
        end

        context 'with a non-numeric key' do
          it 'abort execution and returns an error' do
            expect { subject.run(%w[get praefect.__nodes.first]) }.to raise_error(SystemExit).and output(/ERROR: length on praefect\.__nodes must be a positive number/).to_stderr

            expect_no_error_report
          end
        end

        context 'with an index out of bounds' do
          it 'abort execution and returns an error' do
            expect { subject.run(%w[get praefect.__nodes.100]) }.to raise_error(SystemExit).and output(/ERROR: praefect\.__nodes only has \d+ entries/).to_stderr
          end
        end
      end

      context 'accessing a value on an array' do
        it 'returns the value' do
          expect { subject.run(%w[get praefect.__nodes.0.config_file]) }.to output("gitaly/gitaly-0.praefect.toml\n").to_stdout
        end
      end
    end
  end

  context 'set' do
    context 'with a missing key' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
      end
    end

    context 'with a missing value' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set key]) }.to raise_error(SystemExit).and output(/Usage:/).to_stderr
      end
    end

    context 'with an invalid key' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set invalidkey value]) }.to raise_error(SystemExit).and output(/ERROR: Cannot get config for 'invalidkey'/).to_stderr

        expect_no_error_report
      end
    end

    context 'with an invalid value' do
      it 'issues the usage warning' do
        expect { subject.run(%w[set port a]) }.to raise_error(SystemExit).and output(/ERROR: Value 'a' for setting 'port' is not a valid port/).to_stderr

        expect_no_error_report
      end
    end

    context 'with a valid key and value' do
      let(:current_port) { 3000 }

      context 'where the new value is different' do
        context "but the kdk.yml doesn't have any value set" do
          it 'advises the new value has been set' do
            new_port = 3001

            expect_set("---\nport: #{new_port}\n")
            expect(KDK::Output).to receive(:success).with("'port' is now set to '#{new_port}' (previously using default '#{current_port}').")

            subject.run(%W[set port #{new_port}])
          end
        end

        context "and the kdk.yml has some value set" do
          it 'advises the new value has been set' do
            new_port = 3001

            stub_persisted_kdk_yaml('port' => current_port)

            expect_set("---\nport: #{new_port}\n")
            expect(KDK::Output).to receive(:success).with("'port' is now set to '#{new_port}' (previously '#{current_port}').")

            subject.run(%W[set port #{new_port}])
          end
        end
      end

      context 'where the new value is the same' do
        context "but the kdk.yml doesn't contain the same value" do
          it 'advises the value has been explicitly set' do
            expect_set("---\nport: #{current_port}\n")
            expect(KDK::Output).to receive(:success).with("'port' is now set to '#{current_port}' (explicitly setting '#{current_port}').")

            subject.run(%W[set port #{current_port}])
          end
        end

        context 'and the kdk.yml already contains the same value' do
          it 'advises the current value is already set' do
            stub_persisted_kdk_yaml('port' => current_port)

            expect_kdk_write(nil, negate: true)
            expect(KDK::Output).to receive(:warn).with("'port' is already set to '#{current_port}'")

            subject.run(%W[set port #{current_port}])
          end
        end
      end

      context 'when the setting is an array' do
        it 'sets the value' do
          stub_persisted_kdk_yaml('cells' => { 'enabled' => true, 'instance_count' => 1 })

          expect_set(<<~YAML)
            ---
            cells:
              enabled: true
              instance_count: 1
              instances:
              - id: 5
          YAML

          expect(KDK::Output).to receive(:success)
            .with("'cells.instances.0.id' is now set to '5' (previously using default '2').")

          subject.run(%w[set cells.instances.0.id 5])
        end
      end

      def expect_set(yaml)
        expect(KDK::Output).to receive(:info).with("Don't forget to run 'kdk reconfigure'.")
        expect_kdk_write(yaml)
        expect(stub_backup).to receive(:backup!)
      end

      def expect_kdk_write(yaml, negate: false)
        if negate
          expect(File).not_to receive(:write).with(KDK::Config::FILE, yaml)
        else
          expect(File).to receive(:write).with(KDK::Config::FILE, yaml)
        end
      end
    end
  end
end
