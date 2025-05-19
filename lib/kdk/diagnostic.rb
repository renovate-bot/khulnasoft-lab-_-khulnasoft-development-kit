# frozen_string_literal: true

module KDK
  module Diagnostic
    def self.all
      # Dynamically fetch constants, except :Base
      klasses = constants - [:Base]

      klasses.map do |const|
        const_get(const).new
      end
    end
  end
end
