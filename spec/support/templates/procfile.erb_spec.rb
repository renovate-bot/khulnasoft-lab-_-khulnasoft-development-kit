# frozen_string_literal: true

RSpec.describe 'support/templates/Procfile.erb' do
  let(:source) { |example| example.example_group.top_level_description }

  describe 'lines count', skip: 'Temporarily skipped due to ongoing Procfile deprecation efforts' do
    # See __END__ section at the bottom
    subject(:lines) { File.readlines(source).size }

    # This number should only go down as new services must be written in Ruby.
    # Decrease this number according after converting a legacy service.
    # Thank you
    let(:expected_lines) { Integer(File.read(__FILE__).split('__END__').last) }

    specify do # rubocop:disable RSpec/NoExpectationExample -- We fail manually
      if lines < expected_lines
        content = File.read(__FILE__).sub(/__END__\n.*/, "__END__\n#{lines}")
        File.write(__FILE__, content)

        raise <<~MSG
          Thank you for converting legacy services to Ruby ❤️

          The line count of `#{source}` decreased from #{expected_lines} to #{lines}!

          The binding `expected_lines` in `#{__FILE__}` was adjusted.

          Please commit the changes.
        MSG
      elsif lines > expected_lines
        raise <<~MSG
          The line count of `#{source}` increased from #{expected_lines} to #{lines}!

          Adding new services to `#{source}` is strongly discouraged.
          See https://github.com/khulnasoft-lab/khulnasoft-development-kit/-/issues/904
        MSG
      end
    end
  end
end

__END__
75
