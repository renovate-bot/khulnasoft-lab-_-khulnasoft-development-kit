# frozen_string_literal: true

RSpec.describe KDK::Announcement do
  let(:filepath) { Pathname.new('/tmp/0001_announcement_double.yml') }
  let(:header) { 'the header' }
  let(:body) { 'the body' }

  subject { described_class.new(filepath, header, body) }

  describe '.from_file' do
    it 'creates a new intance of announcement_double' do
      yaml = { 'header' => header, 'body' => body }.to_yaml

      allow(filepath).to receive(:read).and_return(yaml)

      expect(described_class.from_file(filepath)).to be_instance_of(described_class)
    end
  end

  describe '#render?' do
    context 'when not already rendered' do
      it 'returns true' do
        expect(subject.render?).to be_truthy
      end
    end

    context 'already rendered' do
      it 'returns false', :hide_stdout do
        allow(subject).to receive(:update_cached_file).and_return(true)
        subject.render

        expect(subject.render?).to be_falsey
      end
    end
  end

  describe '#render' do
    let(:expected_output_regex) { /#{header}\n◈──────────────────────────────────────────────────────────────────────────────◈\n#{body}\n/ }

    before do
      allow(subject).to receive(:update_cached_file).and_return(true)
      allow(KDK::Output).to receive(:colorize?).and_return(false)
    end

    context 'when not already rendered' do
      it 'displays the announcement_double to stdout' do
        expect(subject).to receive(:read_cache_file_contents!).once.and_call_original

        expect { subject.render }.to output(expected_output_regex).to_stdout
      end
    end

    context 'when already rendered' do
      it 'displays nothing' do
        expect { subject.render }.to output(expected_output_regex).to_stdout

        expect(subject).not_to receive(:read_cache_file_contents!)

        expect { subject.render }.not_to output.to_stdout
      end
    end
  end
end
