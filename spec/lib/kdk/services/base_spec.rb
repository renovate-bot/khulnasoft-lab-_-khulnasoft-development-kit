# frozen_string_literal: true

RSpec.describe KDK::Services::Base do
  subject(:base_service) { described_class.new }

  describe '#name' do
    it 'needs to be implemented' do
      expect { base_service.name }.to raise_error(NotImplementedError)
    end
  end

  describe '#command' do
    it 'needs to be implemented' do
      expect { base_service.command }.to raise_error(NotImplementedError)
    end
  end

  describe '#enabled?' do
    it 'needs to be implemented' do
      expect { base_service.enabled? }.to raise_error(NotImplementedError)
    end
  end

  describe '#validate_env_keys!' do
    let(:dummy_klass) do
      Class.new(described_class) do
        attr_reader :env, :name

        def initialize(env)
          @name = 'dummy'
          @env = env

          super()
        end
      end
    end

    subject(:dummy_service) { dummy_klass.new(envs) }

    shared_examples 'has valid environment' do
      it 'initializes properly' do
        expect { dummy_service }.not_to raise_error
      end
    end

    context 'env is empty' do
      let(:envs) { {} }

      it_behaves_like 'has valid environment'
    end

    context 'env has valid keys' do
      let(:envs) do
        {
          'BLAAT' => 123,
          'HELLO_THERE' => true,
          '__HIDDEN__' => 'ssssht!'
        }
      end

      it_behaves_like 'has valid environment'
    end

    context 'env has key with spaces' do
      let(:envs) { { 'HELLO THERE': false } }

      it 'raises error' do
        expect { dummy_service }.to raise_error(KDK::Services::InvalidEnvironmentKeyError, "Invalid environment keys for 'dummy': [:\"HELLO THERE\"]")
      end
    end
  end
end
