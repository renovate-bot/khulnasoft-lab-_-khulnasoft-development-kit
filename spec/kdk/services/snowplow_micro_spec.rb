# frozen_string_literal: true

RSpec.describe KDK::Services::SnowplowMicro do
  describe '#name' do
    it { expect(subject.name).to eq('snowplow-micro') }
  end

  describe '#command' do
    it 'returns the command' do
      expect(subject.command).to eq('docker run --rm --mount type=bind,source=/home/git/kdk/snowplow,destination=/config -p 9091:9091 snowplow/snowplow-micro:latest --collector-config /config/snowplow_micro.conf --iglu /config/iglu.json')
    end
  end
end
