# frozen_string_literal: true

require 'json'

module KDK
  # This class configures OpenBao dev server secrets persistence for KhulnaSoft
  class OpenBao
    NotRunningError = Class.new(StandardError)

    attr_reader :init_output, :unseal_key, :root_token

    def initialize
      @unseal_key = nil
      @root_token = nil
      @init_output = nil
    end

    def configure
      initialize_server
      set_unseal_key
      set_root_token
      unseal_vault(unseal_key)

      true
    end

    def initialize_server
      return if vault_already_initialized?

      args = %w[operator init -key-shares=1 -key-threshold=1 -format=json]
      @init_output = shellout(args)
    end

    def unseal_vault(unseal_key)
      return KDK::Output.puts('OpenBao is already unsealed') unless vault_sealed?

      args = ['operator', 'unseal', unseal_key]
      shellout(args)

      KDK::Output.success('OpenBao has been unsealed successfully')
    end

    def vault_sealed?
      args = %w[status -format json]

      JSON.parse(shellout(args))['sealed']
    end

    def vault_already_initialized?
      args = %w[operator init -status -format json]

      JSON.parse(shellout(args))['Initialized']
    end

    def set_unseal_key
      if init_output
        @unseal_key = JSON.parse(init_output)['unseal_keys_hex'].pop

        config.bury!('openbao.unseal_key', unseal_key)
        config.save_yaml!
      else
        @unseal_key = config.openbao.unseal_key
      end
    end

    def set_root_token
      if init_output
        @root_token = JSON.parse(init_output)['root_token']

        config.bury!('openbao.root_token', root_token)
        config.save_yaml!
      else
        @root_token = config.openbao.root_token
      end

      KDK::Output.puts("The root token is: #{root_token}") unless root_token.empty?
    end

    private

    def shellout(*args)
      openbao_config = config.openbao

      sh = Shellout.new(
        [openbao_config.bin.to_s].concat(*args),
        env: {
          'BAO_ADDR' => "http://#{openbao_config.__listen}",
          'BAO_TOKEN' => openbao_config.root_token
        }
      )

      result = sh.run
      raise NotRunningError, "Running 'bao #{args.join(' ')} failed: #{sh.read_stderr}" unless sh.read_stderr.empty?

      result
    end

    def config
      KDK.config
    end
  end
end
