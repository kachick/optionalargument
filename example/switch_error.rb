# coding: us-ascii
# frozen_string_literal: true

$VERBOSE = true

require_relative '../lib/optionalargument'

OptArg = OptionalArgument.define {
  opt :a
}

begin
  OptArg.parse({b: 1}, exception: ArgumentError) #=> ArgumentError
rescue
  p $!
end

begin
  OptArg.parse({b: 1}, exception: KeyError)      #=> KeyError
rescue
  p $!
end
