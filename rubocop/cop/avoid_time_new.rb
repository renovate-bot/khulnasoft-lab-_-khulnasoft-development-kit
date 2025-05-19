# frozen_string_literal: true

module RuboCop
  module Cop
    # Cop that discourages use of Time.new
    #
    class AvoidTimeNew < RuboCop::Cop::Base
      MSG = 'Use `Time.now` instead of `Time.new` to ensure our time helpers work effectively.'

      def_node_matcher :time_new?, '(send (const _ :Time) :new)'

      RESTRICT_ON_SEND = %i[new].freeze

      def on_send(node)
        add_offense(node) if time_new?(node)
      end
    end
  end
end
