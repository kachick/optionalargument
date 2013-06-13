# coding: us-ascii

$VERBOSE = true

require_relative '../lib/optionalargument'

OptArg = OptionalArgument.define {
  opt :known, must: true
}

opts = OptArg.parse(
         {known: 1, unknown: 2},
         defined_only: false)      #=> pass