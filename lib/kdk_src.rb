# frozen_string_literal: true

require 'pathname'

module KDK
  # Absolute [Pathname] of the KDK source root
  SRC = Pathname(__dir__).parent.expand_path
end
