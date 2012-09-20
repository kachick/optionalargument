module OptionalArgument

  class ParseError < StandardError; end
  class UndefinedNameError < ParseError; end
  class KeyConflictError < ParseError; end

end
