# frozen_string_literal: true

RSpec.describe KDK::CoreHelper do
  describe KDK::CoreHelper::DeepHash do
    include described_class

    describe '.deep_merge' do
      it 'merges two hashes', :aggregate_failures do
        expect(deep_merge({}, {})).to eq({})
        expect(deep_merge({ a: 23 }, {})).to eq({ a: 23 })
        expect(deep_merge({}, { a: 23 })).to eq({ a: 23 })
        expect(deep_merge({ a: 23 }, { b: 42 })).to eq({ a: 23, b: 42 })
      end

      it 'overrides left' do
        expect(deep_merge({ a: 23 }, { a: 42 })).to eq({ a: 42 })
      end

      it 'merges recursively' do
        expect(
          deep_merge(
            { a: { nested: { b: 23 } } },
            { a: { nested: { c: 42 } } }
          )
        ).to eq(a: { nested: { b: 23, c: 42 } })
      end

      it 'overrides arrays' do
        expect(
          deep_merge(
            { a: [23] },
            { a: [42] }
          )
        ).to eq(a: [42])
      end

      it 'does not transform keys' do
        expect(
          deep_merge(
            { a: 23 },
            { 'a' => 42 }
          )
        ).to eq(a: 23, 'a' => 42)
      end

      it 'does not modify left or right inplace' do
        left = { a: { b: 42 }.freeze }.freeze
        right = { b: 23 }.freeze

        expect(deep_merge(left, right)).to eq(a: { b: 42 }, b: 23)
      end
    end
  end
end
