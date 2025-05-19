# frozen_string_literal: true

RSpec.describe KDK::ConfigRedactor do
  describe '.redact' do
    redacted = '[redacted]'
    home_path_redact = '$HOME'

    shared_examples 'redacts' do |input, output|
      it 'redacts input' do
        output.freeze

        expect(described_class.redact(input)).to eq(output)
      end
    end

    shared_examples 'does not redact' do |input|
      it 'does not redact' do
        output.freeze

        expect(described_class.redact(input)).to eq(input)
      end
    end

    include_examples 'does not redact', {}
    include_examples 'does not redact', { a: 'A' }
    include_examples 'does not redact', { a: %w[A B] }
    include_examples 'does not redact', { a: { b: 'A' } }
    include_examples 'does not redact', { key: '1' }
    include_examples 'does not redact', { secret_key: 1 }
    include_examples 'does not redact', { secret_key: '' }

    include_examples 'redacts', { secret_key: '1' }, { secret_key: redacted }
    include_examples 'redacts', { secret_key: '1234' }, { secret_key: redacted }
    include_examples 'redacts', { secret_key: '12345' }, { secret_key: redacted }
    include_examples 'redacts', { secret_key: '123456' }, { secret_key: redacted }

    # By Key
    include_examples 'redacts', { my_password: '1' }, { my_password: redacted }
    include_examples 'redacts', { my_pass: '1' }, { my_pass: redacted }
    include_examples 'redacts', { my_secret: '1' }, { my_secret: redacted }
    include_examples 'redacts', { my_token: '1' }, { my_token: redacted }
    include_examples 'redacts', { token: '1' }, { token: redacted }
    include_examples 'redacts', { sectoken: '1' }, { sectoken: redacted }
    include_examples 'redacts', { SECRET_KEY: '1' }, { SECRET_KEY: redacted }

    # Allow keys
    include_examples 'does not redact', { cookie_key: '1' }
    include_examples 'does not redact', { version: '1' }

    # By value
    include_examples 'redacts', { a: 'glpat-1234' }, { a: redacted }
    include_examples 'redacts', { a: 'glsoat-1234' }, { a: redacted }
    include_examples 'does not redact', { a: 'glpat_1234' }
    include_examples 'does not redact', { a: 'Glpat-1234' }

    include_examples 'redacts', { a: 'ghp_1234' }, { a: redacted }
    include_examples 'redacts', { a: 'gho_1234' }, { a: redacted }
    include_examples 'does not redact', { a: 'ghp-1234' }
    include_examples 'does not redact', { a: 'ghP-1234' }

    include_examples 'redacts', { a: '741b4ba7c176900c9a2e18f46dcf6ae0' }, { a: redacted }
    include_examples 'redacts', { a: '012345689ABCEDEF' }, { a: redacted }
    include_examples 'does not redact', { a: '0123456' }
    include_examples 'redacts', { a: 'a3530de6-495d-495a-a6d0-50d8d18d17cf' }, { a: redacted }

    include_examples 'redacts', { example_dir: "#{Dir.home}/git/kdk" }, { example_dir: "#{home_path_redact}/git/kdk" }

    # Nested
    include_examples 'does not redact', { secret_key: %w[1 2] }
    include_examples 'redacts',
      { list: [{ secret_key: '1' }, { secret_key: '2' }] },
      { list: [{ secret_key: redacted }, { secret_key: redacted }] }

    include_examples 'redacts',
      { list: [{ secret_key: '1', plain: 'A' }, { secret_key: '2' }] },
      { list: [{ secret_key: redacted, plain: 'A' }, { secret_key: redacted }] }

    include_examples 'redacts',
      { deep: { nested: { secret_key: '1' }, my_pass: '1' } },
      { deep: { nested: { secret_key: redacted }, my_pass: redacted } }
  end

  describe '.redact_logfile' do
    it 'redacts the home path' do
      expect(Dir).to receive(:home).and_return('/home/kdkuser1')

      redacted = subject.redact_logfile <<~LOGFILE
        Running 'make install' in /Users/test/project1
        Updating stuff in /home/dog/projects/kdk...
        error in /home/kdkuser1/kdk
      LOGFILE
      expect(redacted).to eq <<~LOGFILE
        Running 'make install' in /Users/test/project1
        Updating stuff in /home/dog/projects/kdk...
        error in $HOME/kdk
      LOGFILE
    end
  end
end
