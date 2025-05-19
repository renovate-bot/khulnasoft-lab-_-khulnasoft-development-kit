# frozen_string_literal: true

RSpec.describe KDK::Command::Cells do
  include ShelloutHelper

  let(:args) { [] }

  subject(:run) { described_class.new.run(args) }

  before do
    stub_kdk_yaml({})
  end

  shared_examples 'prints usage' do
    it 'aborts execution and returns usage instructions' do
      expect { run }.to raise_error(SystemExit).and output(/WARNING.+ Usage:/).to_stderr
    end
  end

  context 'with no extra argument' do
    it_behaves_like 'prints usage'
  end

  context 'with invalid extra arguments' do
    let(:args) { %w[woof] }

    it_behaves_like 'prints usage'
  end

  %w[up start stop restart status update].each do |command|
    context "'#{command}' sub-command" do
      let(:args) { [command] }

      it "runs and returns CellManager##{command}" do
        expect_any_instance_of(CellManager).to receive(command.to_sym).and_return(true)

        expect(run).to be(true)
      end

      describe "when CellManager##{command} fails" do
        it 'returns false' do
          expect_any_instance_of(CellManager).to receive(command.to_sym).and_return(false)

          expect(run).to be(false)
        end
      end
    end
  end

  context 'run in cell sub-command' do
    let(:args) { %w[cell-2 config get cells.enabled] }
    let(:cell_exist) { true }
    let(:success) { true }
    let(:sh) { kdk_shellout_double(success?: success) }

    before do
      allow_any_instance_of(CellManager).to receive(:cell_exist?).with(2).and_return(cell_exist)
    end

    it 'runs CellManager#run_in_cell' do
      expect_any_instance_of(CellManager).to receive(:run_in_cell).with(2, args.drop(1)).and_return(sh)

      expect(run).to be(true)
    end

    context 'when the cell does not exist' do
      let(:cell_exist) { false }

      it_behaves_like 'prints usage'
    end

    context 'when CellManager#run_in_cell fails' do
      let(:success) { false }

      it 'returns false' do
        expect(run).to be(false)
      end
    end
  end
end
