# coding: us-ascii
# frozen_string_literal: true

$VERBOSE = true

require_relative '../lib/optionalargument'

OptArg = OptionalArgument.define {
  opt :x, condition: 3..5
  opt :y, condition: AND(Float, 3..5)
  opt :z, adjuster: ->arg{Float arg}
}

p OptArg.parse({x: 5})       #=> pass : 5 is sufficient for 3..5

begin
  OptArg.parse({x: 6})       #=> Error: 6 is deficient for 3..5
rescue
  p $!
end

begin
  OptArg.parse({y: 5})      #=> Error: 5 is deficient for Float
rescue
  p $!
end

p OptArg.parse({y: 5.0})    #=> pass : 5.0 is sufficient for 3..5 and Float
p OptArg.parse({z: '1'}).z  #=> 1.0  : casted under adjuster
