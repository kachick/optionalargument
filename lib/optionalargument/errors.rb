# coding: us-ascii

module OptionalArgument

  class MalformedOptionsError < TypeError; end
  class KeyConflictError < MalformedOptionsError; end

end