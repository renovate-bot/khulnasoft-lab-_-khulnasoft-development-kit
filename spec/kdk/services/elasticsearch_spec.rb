# frozen_string_literal: true

RSpec.describe KDK::Services::Elasticsearch do
  describe '#name' do
    it { expect(subject.name).to eq('elasticsearch') }
  end

  describe '#command' do
    it { expect(subject.command).to eq("elasticsearch/bin/elasticsearch") }
  end
end
