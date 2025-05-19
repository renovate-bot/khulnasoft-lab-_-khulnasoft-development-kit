# frozen_string_literal: true

RSpec.describe KDK::Diagnostic do
  describe '.all' do
    it 'creates instances of all KDK::Diagnostic classes' do
      expect { described_class.all }.not_to raise_error
    end

    it 'contains only diagnostic classes' do
      diagnostic_classes = (KDK::Diagnostic.constants - [:Base]).map do |const|
        KDK::Diagnostic.const_get(const)
      end

      expect(described_class.all.map(&:class)).to eq(diagnostic_classes)
    end
  end
end
