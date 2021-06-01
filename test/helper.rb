# coding: us-ascii
# frozen_string_literal: true

require 'stringio'
require 'warning'

# How to use => https://test-unit.github.io/test-unit/en/
require 'test/unit'

require 'irb'
require 'power_assert/colorize'
require 'irb/power_assert'

if Warning.respond_to?(:[]=) # @TODO Removable this guard after dropped ruby 2.6
  Warning[:deprecated] = true
  Warning[:experimental] = true
end

Warning.process do |warning|
  case warning
  when /`older` is deprecated, use `newer`/
    :default
  else
    :raise
  end
end

require_relative '../lib/optionalargument'
