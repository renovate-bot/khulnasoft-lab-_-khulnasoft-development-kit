# frozen_string_literal: true

RSpec.describe KDK::OpenBao do
  include ShelloutHelper

  let(:mock_shellout) { kdk_shellout_double(run: output) }

  subject(:open_bao) { described_class.new }

  before do
    allow_kdk_shellout.and_return(mock_shellout)
    allow(mock_shellout).to receive(:run)
    allow(mock_shellout).to receive(:execute)
    allow(KDK::Output).to receive(:puts)
    allow(KDK::Output).to receive(:success)
  end

  describe '#configure' do
    subject(:configure) { open_bao.configure }

    it 'calls the necessary methods in order' do
      expect(open_bao).to receive(:initialize_server).ordered
      expect(open_bao).to receive(:set_unseal_key).ordered
      expect(open_bao).to receive(:set_root_token).ordered
      expect(open_bao).to receive(:unseal_vault).ordered

      expect(configure).to be(true)
    end
  end

  describe '#initialize_server' do
    let(:config) { KDK.config }
    let(:bao) { config.openbao.bin }

    subject(:initialize_server) { open_bao.initialize_server }

    context 'when vault is not initialized' do
      before do
        allow(open_bao).to receive(:vault_already_initialized?).and_return(false)
      end

      it 'initializes the server' do
        expect_shellout(
          %W[#{bao} operator init -key-shares=1 -key-threshold=1 -format=json],
          { env: { 'BAO_ADDR' => 'http://127.0.0.1:8200', 'BAO_TOKEN' => '' } }
        )

        initialize_server
      end
    end

    context 'when vault is already initialized' do
      before do
        allow(open_bao).to receive(:vault_already_initialized?).and_return(true)
      end

      it 'does not initialize the server' do
        expect_no_kdk_shellout.with('bao operator init')

        initialize_server
      end
    end
  end

  describe '#unseal_vault' do
    let(:config) { KDK.config }
    let(:bao) { config.openbao.bin }
    let(:keys) { 'key1' }

    subject(:unseal_vault) { open_bao.unseal_vault(keys) }

    context 'when vault is sealed' do
      before do
        allow(open_bao).to receive(:vault_sealed?).and_return(true)
      end

      it 'unseals the vault' do
        expect_shellout(
          %W[#{bao} operator unseal key1],
          { env: { 'BAO_ADDR' => 'http://127.0.0.1:8200', 'BAO_TOKEN' => '' } }
        )

        expect(KDK::Output).to receive(:success).with('OpenBao has been unsealed successfully')

        unseal_vault
      end
    end

    context 'when vault is already unsealed' do
      before do
        allow(open_bao).to receive(:vault_sealed?).and_return(false)
      end

      it 'does not unseal the vault' do
        expect(open_bao).not_to receive(:shellout)
        expect(KDK::Output).to receive(:puts).with('OpenBao is already unsealed')

        unseal_vault
      end
    end

    context 'when openbao is not running' do
      before do
        allow(open_bao).to receive(:vault_sealed?).and_raise(KDK::OpenBao::NotRunningError)
      end

      it 'raises an error' do
        expect { unseal_vault }.to raise_error(KDK::OpenBao::NotRunningError)
      end
    end
  end

  describe '#set_unseal_key' do
    subject(:set_unseal_key) { open_bao.set_unseal_key }

    context 'when init_output is present' do
      let(:init_output) { "{\"unseal_keys_hex\": [\n\"123456789\"\n ]}" }

      before do
        allow(open_bao).to receive(:init_output).and_return(init_output)
        allow(KDK.config).to receive(:bury!)
        allow(KDK.config).to receive(:save_yaml!)
      end

      it 'sets the unseal keys from init_output' do
        set_unseal_key

        expect(open_bao.instance_variable_get(:@unseal_key)).to eq('123456789')
      end

      it 'saves the keys to the config' do
        expect(KDK.config).to receive(:bury!).with('openbao.unseal_key', '123456789')
        expect(KDK.config).to receive(:save_yaml!)

        set_unseal_key
      end
    end

    context 'when init_output is not present' do
      before do
        allow(open_bao).to receive(:init_output).and_return(nil)
        allow(KDK.config).to receive_message_chain(:openbao, :unseal_key).and_return('123456789')
      end

      it 'sets the unseal keys from the config' do
        set_unseal_key

        expect(open_bao.instance_variable_get(:@unseal_key)).to eq('123456789')
      end
    end
  end

  describe '#set_root_token' do
    subject(:set_root_token) { open_bao.set_root_token }

    context 'when init_output is present' do
      let(:init_output) { "{\"root_token\": \"root_token_123\"\n}" }

      before do
        allow(open_bao).to receive(:init_output).and_return(init_output)
        allow(KDK.config).to receive(:bury!)
        allow(KDK.config).to receive(:save_yaml!)
      end

      it 'sets the root token from init_output' do
        set_root_token

        expect(open_bao.instance_variable_get(:@root_token)).to eq('root_token_123')
      end

      it 'saves the root token to the config' do
        expect(KDK.config).to receive(:bury!).with('openbao.root_token', 'root_token_123')
        expect(KDK.config).to receive(:save_yaml!)

        set_root_token
      end

      it 'outputs the root token' do
        expect(KDK::Output).to receive(:puts).with('The root token is: root_token_123')

        set_root_token
      end
    end

    context 'when init_output is not present' do
      before do
        allow(open_bao).to receive(:init_output).and_return(nil)
        allow(KDK.config).to receive_message_chain(:openbao, :root_token).and_return('config_root_token')
      end

      it 'sets the root token from the config' do
        set_root_token

        expect(open_bao.instance_variable_get(:@root_token)).to eq('config_root_token')
      end

      it 'outputs the root token' do
        expect(KDK::Output).to receive(:puts).with('The root token is: config_root_token')

        set_root_token
      end
    end
  end

  private

  def expect_shellout(cmd, args, output: '')
    shellout_double = kdk_shellout_double(run: output)
    allow(shellout_double).to receive(:read_stderr).and_return('')

    expect_kdk_shellout_command(cmd, args).and_return(shellout_double)
  end
end
