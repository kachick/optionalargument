# coding: us-ascii
# frozen_string_literal: true

$VERBOSE = true

require_relative '../lib/optionalargument'

OptArg = OptionalArgument.define {
  opt :known, must: true
}

OptArg.parse({known: 1, unknown: 2}, defined_only: false) #=> pass
