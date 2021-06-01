# coding: us-ascii
# frozen_string_literal: true

$VERBOSE = true

require_relative '../lib/optionalargument'

OptArg = OptionalArgument.define {
  opt :a
  opt :b
  conflict :a, :b
  opt :c, requirements: [:b, :d]
  opt :d, aliases: [:d2, :d3]
  opt :e, deprecateds: [:e2, :e3]
}

begin
  OptArg.parse({a: 1, b: 1}) #=> Error: conflict combination thrown: a, b'
rescue
  p $!
end

begin
  OptArg.parse({c: 1})       #=> Error: `c` requires  `b` and `d`
rescue
  p $!
end

p OptArg.parse({d2: 1}).d3   #=> 1
p OptArg.parse({e2: 1}).e3   #=> 1 with warning "`e2` is deprecated, use `e`"
