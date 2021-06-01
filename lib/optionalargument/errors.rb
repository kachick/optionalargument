# coding: us-ascii
# frozen_string_literal: true

module OptionalArgument
  class MalformedOptionsError < TypeError; end
  class KeyConflictError < MalformedOptionsError; end
end
