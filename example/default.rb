# coding: us-ascii
# frozen_string_literal: true

$VERBOSE = true

require_relative '../lib/optionalargument'

OptArg = OptionalArgument.define {
  opt :a
  opt :b, default: 'This is a default value'
}

p OptArg.parse({a: 1}).b  #=> 'This is a default value'
