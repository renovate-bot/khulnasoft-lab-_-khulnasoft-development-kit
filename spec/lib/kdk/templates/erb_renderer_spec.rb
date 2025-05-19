# frozen_string_literal: true

RSpec.describe KDK::Templates::ErbRenderer do
  let(:protected_config_files) { [] }
  let(:erb_file) { fixture_path.join('example.erb') }
  let(:out_file) { temp_path.join('some/example.out') }
  let(:config) { config_klass.new(yaml: { 'kdk' => { 'protected_config_files' => protected_config_files } }) }
  let(:locals) do
    { foo: 'foobar', bar: 'barfoo' }
  end

  let(:config_klass) do
    Class.new(KDK::ConfigSettings) do
      string(:foo) { 'foo' }
      string(:bar) { 'bar' }

      settings(:kdk) do
        array(:protected_config_files) { [] }
        bool(:overwrite_changes) { false }
      end
    end
  end

  subject(:renderer) { described_class.new(erb_file.to_s, **locals) }

  before do
    allow(KDK).to receive(:config) { config }
  end

  around do |example|
    out_file.parent.mkpath

    example.run
  ensure
    out_file.parent.rmtree
  end

  describe '#safe_render!' do
    context 'output file does not exist' do
      it 'renders without a warning' do
        expect(KDK::Output).not_to receive(:warn)

        expect(renderer.safe_render!(out_file)).to be true

        expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
      end

      context 'with protected config file match', :hide_stdout do
        let(:protected_config_files) { ['some/example.out'] }

        it 'renders with a warning' do
          expect(KDK::Output).to receive(:warn).with(%r{Creating missing protected file 'some/example.out'.})

          expect(renderer.safe_render!(out_file)).to be true

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end
      end
    end

    context 'output file exists' do
      before do
        File.write(out_file, contents)
      end

      context 'with differences' do
        let(:contents) { 'Foo is bar' }

        it 'warns about changes and overwrites content', :hide_stdout do
          expect(KDK::Output).to receive(:warn).with(%r{'some/example.out' has been overwritten})
          expect(renderer).to receive(:display_changes!)

          expect(renderer.safe_render!(out_file)).to be true

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end

        context 'and yielded block raises an error' do
          before do
            allow(renderer).to receive(:perform_backup!).and_raise('some error')
          end

          it 'warns about changes and content', :hide_stdout do
            expect(KDK::Output).not_to receive(:warn).with(%r{'some/example.out' has been overwritten})
            expect(renderer).to receive(:display_changes!)

            expect { renderer.safe_render!(out_file) }.to raise_error('some error')

            expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
          end
        end

        context 'with protected config file match', :hide_stdout do
          let(:protected_config_files) { ['some/*.out'] }

          it 'warns about changes and does not overwrite content' do
            expect(KDK::Output).to receive(:warn).with(%r{Changes to 'some/example.out' not applied because it's protected in kdk.yml.})

            expect(renderer.safe_render!(out_file)).to be false

            expect(File.read(out_file)).to match('Foo is bar')
          end
        end
      end

      context 'without differences' do
        let(:contents) { renderer.render_to_string }

        it 'renders without a warning' do
          expect(renderer).not_to receive(:display_changes!)

          expect(renderer.safe_render!(out_file)).to be false

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end
      end
    end
  end

  describe '#render' do
    context 'output file does not exist' do
      it 'renders without a warning' do
        expect(KDK::Output).not_to receive(:warn)

        renderer.render(out_file)

        expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
      end

      context 'with protected config file match', :hide_stdout do
        let(:protected_config_files) { ['some/example.out'] }

        it 'renders with a warning' do
          expect(KDK::Output).to receive(:warn).with(%r{Creating missing protected file 'some/example.out'.})

          renderer.render(out_file)

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end
      end
    end

    context 'output file exists' do
      before do
        File.write(out_file, contents)
      end

      context 'with differences' do
        let(:contents) { 'Foo is bar' }

        it 'renders without a warning' do
          expect(KDK::Output).not_to receive(:warn)

          renderer.render(out_file)

          expect(File.read(out_file)).to match('Foo is foo, and Bar is bar')
        end

        context 'with protected config file match', :hide_stdout do
          let(:protected_config_files) { ['some/*.out'] }

          it 'warns about changes and does not overwrite content' do
            expect(KDK::Output).to receive(:warn).with(%r{Changes to 'some/example.out' not applied because it's protected in kdk.yml.})

            renderer.render(out_file)

            expect(File.read(out_file)).to match('Foo is bar')
          end
        end
      end
    end
  end

  describe '#render_to_string' do
    it 'renders the template with correct assigned config values' do
      expect(renderer.render_to_string).to match('Foo is foo, and Bar is bar')
    end

    it 'renders the template with correct assigned local values' do
      expect(renderer.render_to_string).to match('Local var foo is foobar and bar is barfoo')
    end
  end
end
