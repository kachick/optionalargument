# coding: us-ascii
# frozen_string_literal: true

require_relative 'helper'

class TestOptionalArgumentREADME < Test::Unit::TestCase

  OptArg1 = OptionalArgument.define {
    opt :full_name, must: true, aliases: [:name, :fullname]
    opt :favorite, default: 'Ruby'
  }

  OptArg2 = OptionalArgument.define {
    opt :a
    opt :b, aliases: [:b1]
    opt :c, aliases: [:c1, :c2]
    conflict :a, :c
  }

  def test_define
    assert_same OptionalArgument::Store, OptArg1.superclass
  end

  def test_func1
    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg1.parse({})
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg1.parse({ favorite: true})
    end

    ret = OptArg1.parse({ name: 'John'})

    assert_instance_of OptArg1, ret
    assert_equal 'John', ret.name
    assert_equal 'Ruby', ret.favorite

    ret = OptArg1.parse({ favorite: 'Scala', name: nil})
    assert_equal 'Scala', ret.favorite
  end

  def test_func2
    ret = OptArg2.parse({})

    assert_same false, ret.with_a?
    assert_same false, ret.a?
    assert_same false, ret.with_b?
    assert_same false, ret.with_b1?
    assert_same false, ret.b?
    assert_same false, ret.b1?
    assert_same false, ret.with_c?
    assert_same false, ret.with_c1?
    assert_same false, ret.with_c2?
    assert_same false, ret.c?
    assert_same false, ret.c1?
    assert_same false, ret.c2?

    assert_same nil, ret.a
    assert_same nil, ret.b
    assert_same nil, ret.b1
    assert_same nil, ret.c
    assert_same nil, ret.c1
    assert_same nil, ret.c2
    assert_same nil, ret[:a]
    assert_same nil, ret[:b]
    assert_same nil, ret[:b1]
    assert_same nil, ret[:c]
    assert_same nil, ret[:c1]
    assert_same nil, ret[:c2]

    assert_raises NoMethodError do
      ret.a1
    end

    assert_raises KeyError do
      ret[:a1]
    end

    assert_raises NoMethodError do
      ret.x
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg2.parse({ a2: true})
    end

    assert_raises ArgumentError do
      OptArg2.parse({a2: true}, exception: ArgumentError)
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg2.parse({a2: true}, defined_only: true)
    end

    assert_instance_of OptArg2, OptArg2.parse({a2: true}, defined_only: false)

    assert_raises OptionalArgument::KeyConflictError do
      OptArg2.parse({ a: true, c: true})
    end

    assert_raises OptionalArgument::KeyConflictError do
      OptArg2.parse({ a: true, c: true, b: true})
    end

    assert_raises OptionalArgument::KeyConflictError do
      OptArg2.parse({ a: true, c2: true, b: true})
    end

    assert_raises OptionalArgument::KeyConflictError do
      OptArg2.parse({a: true, c: true}, defined_only: false)
    end

    assert_raises KeyError do
      OptArg2.parse({a: true, c: true}, exception: KeyError)
    end

    assert_raises OptionalArgument::KeyConflictError do
      OptArg2.parse({a: true, c: true, b: true}, defined_only: false)
    end

    assert_raises OptionalArgument::KeyConflictError do
      OptArg2.parse({a: true, c2: true, b: true}, defined_only: false)
    end
  end

end
