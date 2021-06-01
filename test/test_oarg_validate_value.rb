# coding: us-ascii
# frozen_string_literal: true

require_relative 'helper'

class TestOptionalArgumentValidateValues < Test::Unit::TestCase

  OptArg = OptionalArgument.define {
    opt 'included space :)'
    opt :with_cond, condition: AND(/\AFOO\z/, Symbol)
    opt :with_adj, adjuster: ->arg{arg.to_sym}
    opt :with_cond_adj, condition: AND(/\AFOO\z/, Symbol),
                        adjuster: ->arg{arg.to_sym}
  }

  def test_strange_key
    oarg = OptArg.parse({ 'included space :)': 123})
    assert oarg.public_methods.include?(:'included space :)')
    assert_same 123, oarg[:'included space :)']
    assert_same 123, oarg.public_send(:'included space :)')
  end

  def test_with_cond
    oarg = OptArg.parse({with_cond: :FOO})
    assert_same :FOO, oarg.fetch_by_with_cond
    assert_same :FOO, oarg.with_cond
    assert_same true, oarg.with_with_cond?
    assert_same true, oarg.with_cond?

    assert_raises Validation::InvalidWritingError do
      OptArg.parse({with_cond: 'FOO'})
    end

    assert_raises ArgumentError do
      OptArg.parse({with_cond: 'FOO'}, exception: ArgumentError)
    end

    assert_raises Validation::InvalidWritingError do
      OptArg.parse({with_cond: :BAR})
    end
  end

  def test_with_adj
    oarg = OptArg.parse({with_adj: 'foo'})
    assert_not_equal 'foo', oarg.fetch_by_with_adj
    assert_same :foo, oarg.fetch_by_with_adj

    assert_raises Validation::InvalidAdjustingError do
      OptArg.parse({with_adj: Object.new})
    end

    assert_raises ArgumentError do
      OptArg.parse({wwith_adj: Object.new}, exception: ArgumentError)
    end
  end

  def test_with_cond_adj
    oarg = OptArg.parse({with_cond_adj: 'FOO'})
    assert_not_equal 'FOO', oarg.fetch_by_with_cond_adj
    assert_same :FOO, oarg.fetch_by_with_cond_adj

    assert_raises Validation::InvalidAdjustingError do
      OptArg.parse({with_cond_adj: Object.new})
    end

    assert_raises Validation::InvalidWritingError do
      OptArg.parse({with_cond_adj: 'foo'})
    end
  end

  OptArg2 = OptionalArgument.define {
    opt :with_cond_default, condition: AND(/\AFOO\z/, Symbol),
                            default: 'FOO'
  }

  def test_with_cond_default
    assert_raises Validation::InvalidWritingError do
      OptArg2.parse({})
    end

    oarg = OptArg2.parse({with_cond_default: :FOO})
    assert_not_equal 'FOO', oarg.fetch_by_with_cond_default
    assert_same :FOO, oarg.fetch_by_with_cond_default
  end


  OptArg3 = OptionalArgument.define {
    opt :with_cond_adj_default, condition: AND(/\AFOO\z/, Symbol),
                                default: 'FOO',
                                adjuster: ->arg{arg.to_sym}
  }

  def test_with_cond_adj_default
    oarg = OptArg3.parse({})
    assert_not_equal 'FOO', oarg.fetch_by_with_cond_adj_default
    assert_same :FOO, oarg.fetch_by_with_cond_adj_default
  end

end
