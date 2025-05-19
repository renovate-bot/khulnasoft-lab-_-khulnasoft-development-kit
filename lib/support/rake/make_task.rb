# frozen_string_literal: true

module Support
  module Rake
    MakeTask = Struct.new('MakeTask', :target, :enabled, keyword_init: true) do
      def skip?
        !enabled
      end
    end
  end
end
