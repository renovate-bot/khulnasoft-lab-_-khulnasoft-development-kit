# frozen_string_literal: true

require 'kdk'

module KDK
  # TaskHelpers are used by raketasks to include functionality that would not
  # make sense to be part of "regular KDK" API.
  #
  # There is also expectation that because this is tightly coupled with tasks
  # code executed here is allowed to terminate the flow with `exit()` or
  # raise unhandled exceptions.
  #
  # IMPORTANT: Other parts of the codebase should NEVER rely on code inside
  # TaskHelpers.
  module TaskHelpers
  end
end
