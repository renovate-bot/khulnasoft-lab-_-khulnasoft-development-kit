# frozen_string_literal: true

RSpec.describe Support::Rake::TaskLogger do
  let(:task) { instance_double(Rake::Task, name: 'test task') }
  let(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }
  let(:expected_path) { Pathname("#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279/test-task.log") }

  subject(:task_logger) { described_class.from_task(task) }

  before do
    allow(described_class).to receive(:start_time).and_return(now)
    allow(File).to receive(:symlink?).with("#{KDK.root}/log/kdk/rake-latest").and_return(false)
    allow(File).to receive(:readlink).with("#{KDK.root}/log/kdk/rake-latest").and_return(nil)
  end

  after do
    described_class.set_current!(nil)
  end

  describe '.current' do
    it 'returns nil by default' do
      expect(described_class.current).to be_nil
    end

    context 'after calling .set_current!' do
      before do
        described_class.set_current!(subject)
      end

      it 'returns the current logger' do
        expect(described_class.current).to be(subject)
      end
    end
  end

  describe '#initialize' do
    let(:expected_log_dir) { "#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279" }

    it 'creates the log dir' do
      expect(Dir.glob(subject.file_path.parent).first).to eq(expected_log_dir)

      subject
    end
  end

  describe '#file_path' do
    it 'returns the task- and date-specific file name' do
      expect(subject.file_path).to eq(expected_path)
    end

    context 'when the task name contains filesystem-relevant chracters' do
      let(:task) { instance_double(Rake::Task, name: 'gitlab/doc/api/graphql/reference/khulnasoft_schema.json') }
      let(:now) { DateTime.parse('2021-05-06 18:50:31.279931 +0000').to_time }
      let(:expected_path) { Pathname("#{KDK.root}/log/kdk/rake-2021-05-06_18-50-31_279/gitlab-doc-api-graphql-reference-khulnasoft_schema-json.log") }

      it 'escapes the task name' do
        expect(subject.file_path).to eq(expected_path)
      end
    end
  end

  describe '#file' do
    it 'opens a file based on the task name once' do
      f = file_double(size: 1)
      expect(File).to receive(:open).with(expected_path, 'w').once.and_return(f)

      expect(subject.file).to be(f)
      expect(subject.file).to be(f)
    end
  end

  describe '#cleanup!' do
    context 'when the log file was created' do
      let(:written_bytes) { 0 }
      let(:file) { file_double(size: written_bytes) }

      before do
        closed = false
        allow(File).to receive(:open).with(expected_path, 'w').and_return(file)
        allow(file).to receive(:closed?) { closed }
        allow(file).to receive(:close) do
          raise "tried closing closed file" if closed

          closed = true
        end
      end

      context 'when it was written to' do
        let(:written_bytes) { 42 }

        it 'only closes it' do
          expect(File).not_to receive(:delete)
          expect(file).to receive(:close)

          subject.file
          subject.cleanup!
        end
      end

      context 'when it is empty' do
        it 'closes and deletes it' do
          expect(File).to receive(:delete).with(expected_path)
          expect(file).to receive(:close)

          subject.file
          subject.cleanup!
        end

        context 'when delete: false is passed' do
          it 'only closes it' do
            expect(File).not_to receive(:delete).with(expected_path)
            expect(file).to receive(:close)

            subject.file
            subject.cleanup!(delete: false)
          end

          context 'when cleaning up multiple times' do
            it 'only runs once' do
              expect(File).not_to receive(:delete).with(expected_path)
              expect(file).to receive(:close).once

              subject.file
              subject.cleanup!(delete: false)
            end
          end
        end
      end
    end

    context 'when the log file was not created' do
      it 'does nothing' do
        expect(File).not_to receive(:delete)

        subject.cleanup!
      end
    end
  end

  describe '#recent_line' do
    subject { task_logger.recent_line }

    context 'without previous records' do
      it { is_expected.to be_nil }
    end

    context 'with records' do
      {
        nil => nil,
        '' => nil,
        '------' => nil,
        'single line' => 'single line',
        '5' => '5',
        "a\nb" => 'b',
        "--\na\n  \nb\n -- \n \n" => 'b',
        "a\nfile:23: DEPRECATION WARNING: beware!\n" => 'a'
      }.each do |input, expected|
        context "with input: #{input.inspect}" do
          before do
            task_logger.record_input(input)
          end

          it { is_expected.to eq(expected) }
        end
      end
    end
  end

  describe '#tail' do
    let(:content) { (0..30).map { |i| "An error occurred #{i}" }.join("\n") }

    before do
      allow(File).to receive(:read).with(expected_path).and_return(content)
    end

    it 'returns the last 25 lines' do
      expect(subject.tail).to eq <<~MESSAGE.strip
        An error occurred 6
        An error occurred 7
        An error occurred 8
        An error occurred 9
        An error occurred 10
        An error occurred 11
        An error occurred 12
        An error occurred 13
        An error occurred 14
        An error occurred 15
        An error occurred 16
        An error occurred 17
        An error occurred 18
        An error occurred 19
        An error occurred 20
        An error occurred 21
        An error occurred 22
        An error occurred 23
        An error occurred 24
        An error occurred 25
        An error occurred 26
        An error occurred 27
        An error occurred 28
        An error occurred 29
        An error occurred 30

        See #{expected_path} for the full log.
      MESSAGE
    end

    context 'with a Ruby backtrace logged' do
      let(:content) do
        <<~MESSAGE
          (irb):3:in `<main>': test error (StandardError)
            from <internal:kernel>:187:in `loop'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/lib/ruby/gems/3.3.0/gems/irb-1.15.1/exe/irb:9:in `<top (required)>'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `load'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `<main>'
        MESSAGE
      end

      it 'hides gem paths' do
        expect(subject.tail).to eq <<~MESSAGE.strip
          (irb):3:in `<main>': test error (StandardError)
            from <internal:kernel>:187:in `loop'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `load'
            from /home/kdk/.local/share/mise/installs/ruby/3.3.7/bin/irb:25:in `<main>'

          See #{expected_path} for the full log.
        MESSAGE
      end

      context 'and "exclude_gems" set to false' do
        it 'returns the original backtrace' do
          expect(subject.tail(exclude_gems: false)).to eq(content.strip)
        end
      end
    end
  end

  describe 'Kernel overwrite' do
    let(:buffer) { StringIO.new }

    before do
      f = file_double
      allow(File).to receive(:open).with(expected_path, 'w').once.and_return(f)
      allow(f).to receive(:write) { |d| buffer.write(d) }
      allow(f).to receive(:size).and_return(buffer.size)
    end

    it 'does not overwrite by default' do
      expect { puts "hi" }.to output("hi\n").to_stdout
      expect { warn "hi" }.to output("hi\n").to_stderr
    end

    it "writes to the current thread's TaskLogger" do
      described_class.set_current!(subject)

      expect { puts "hi" }.not_to output.to_stdout
      expect { warn "hi" }.not_to output.to_stderr
      expect(buffer.string).to eq("hihi\n")

      expect do
        Thread.new do
          expect { puts "hi" }.to output("hi\n").to_stdout
          expect { warn "hi" }.to output("hi\n").to_stderr
        end.join

        described_class.set_current!(nil)

        expect { puts "hi" }.to output("hi\n").to_stdout
        expect { warn "hi" }.to output("hi\n").to_stderr
      end.not_to change { buffer.string }
    end
  end

  def file_double(**args)
    instance_double(File, :sync= => true, **args)
  end
end
