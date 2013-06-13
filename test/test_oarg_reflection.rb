# coding: us-ascii

require_relative 'helper'

class Test_OptionalArgument_Reflection < Test::Unit::TestCase

  OptArg = OptionalArgument.define {
    opt :a
    opt :b, aliases: [:b1]
    opt :c, aliases: [:c1, :c2]
    opt :d, deprecateds: [:d1]
    opt :e, deprecateds: [:e1, :e2]
    opt :z
    conflict :a, :z
  }

  def test_autonyms
    assert_equal [:a, :b, :c, :d, :e, :z], OptArg.autonyms
    assert_not_same OptArg.autonyms, OptArg.autonyms
  end

  def test_names
    assert_equal({a: :a, b: :b, b1: :b, c: :c, c1: :c, c2: :c, d: :d, d1: :d, e: :e, e1: :e, e2: :e, z: :z}, OptArg.names)
    assert_not_same OptArg.names, OptArg.names
  end

  def test_members
    assert_equal([:a, :b, :b1, :c, :c1, :c2, :d, :d1, :e, :e1, :e2, :z], OptArg.members)
    assert_not_same OptArg.members, OptArg.members
  end

  def test_aliases
    assert_equal([:b1, :c1, :c2], OptArg.aliases)
    assert_not_same OptArg.aliases, OptArg.aliases
  end

  def test_deprecateds
    assert_equal([:d1, :e1, :e2], OptArg.deprecateds)
    assert_not_same OptArg.deprecateds, OptArg.deprecateds
  end

  def test_autonym?
    assert_equal(true, OptArg.autonym?(:a))
    assert_equal(true, OptArg.autonym?("a"))
    assert_equal(true, OptArg.autonym?(:b))
    assert_equal(true, OptArg.autonym?(:c))
    assert_equal(true, OptArg.autonym?(:d))
    assert_equal(true, OptArg.autonym?(:e))
    assert_equal(true, OptArg.autonym?(:z))
    assert_equal(false, OptArg.autonym?(:b1))
    assert_equal(false, OptArg.autonym?(:c1))
    assert_equal(false, OptArg.autonym?(:c2))
    assert_equal(false, OptArg.autonym?(:d1))
    assert_equal(false, OptArg.autonym?(:e1))
    assert_equal(false, OptArg.autonym?(:e2))
    assert_equal(false, OptArg.autonym?(:undefined))
  end

  def test_member?
    assert_equal(true, OptArg.member?(:a))
    assert_equal(true, OptArg.member?("a"))
    assert_equal(true, OptArg.member?(:b))
    assert_equal(true, OptArg.member?(:c))
    assert_equal(true, OptArg.member?(:d))
    assert_equal(true, OptArg.member?(:e))
    assert_equal(true, OptArg.member?(:z))
    assert_equal(true, OptArg.member?(:b1))
    assert_equal(true, OptArg.member?(:c1))
    assert_equal(true, OptArg.member?(:c2))
    assert_equal(true, OptArg.member?(:d1))
    assert_equal(true, OptArg.member?(:e1))
    assert_equal(true, OptArg.member?(:e2))
    assert_equal(false, OptArg.member?(:undefined))
  end

  def test_aliased?
    assert_equal(false, OptArg.aliased?(:a))
    assert_equal(false, OptArg.aliased?("a"))
    assert_equal(false, OptArg.aliased?(:b))
    assert_equal(false, OptArg.aliased?(:c))
    assert_equal(false, OptArg.aliased?(:d))
    assert_equal(false, OptArg.aliased?(:e))
    assert_equal(false, OptArg.aliased?(:z))
    assert_equal(true, OptArg.aliased?(:b1))
    assert_equal(true, OptArg.aliased?(:c1))
    assert_equal(true, OptArg.aliased?(:c2))
    assert_equal(false, OptArg.aliased?(:d1))
    assert_equal(false, OptArg.aliased?(:e1))
    assert_equal(false, OptArg.aliased?(:e2))
    assert_equal(false, OptArg.aliased?(:undefined))
  end

  def test_deprecated?
    assert_equal(false, OptArg.deprecated?(:a))
    assert_equal(false, OptArg.deprecated?("a"))
    assert_equal(false, OptArg.deprecated?(:b))
    assert_equal(false, OptArg.deprecated?(:c))
    assert_equal(false, OptArg.deprecated?(:d))
    assert_equal(false, OptArg.deprecated?(:e))
    assert_equal(false, OptArg.deprecated?(:z))
    assert_equal(false, OptArg.deprecated?(:b1))
    assert_equal(false, OptArg.deprecated?(:c1))
    assert_equal(false, OptArg.deprecated?(:c2))
    assert_equal(true, OptArg.deprecated?(:d1))
    assert_equal(true, OptArg.deprecated?(:e1))
    assert_equal(true, OptArg.deprecated?(:e2))
    assert_equal(false, OptArg.deprecated?(:undefined))
  end

end