# frozen_string_literal: true

RSpec.describe KDK::OutputBuffered do
  describe '#stdout_handle' do
    it 'returns output' do
      expect(subject.stdout_handle).to be_instance_of(StringIO)
    end
  end

  describe '#stderr_handle' do
    it 'returns output' do
      expect(subject.stderr_handle).to be_instance_of(StringIO)
    end
  end

  describe '#dump' do
    it 'returns output as a string' do
      expect(subject.dump).to eq('')
    end
  end
end
