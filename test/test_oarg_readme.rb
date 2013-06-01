require_relative 'helper'

class Test_OptionalArgument_README < Test::Unit::TestCase

  class Foo

    FUNC1_OPTIONS = OptionalArgument.define {
      opt :full_name, must: true, aliases: [:name, :fullname] 
      opt :favorite, default: 'Ruby'
    }

    FUNC2_OPTIONS = OptionalArgument.define {
      opt :a
      opt :b, aliases: [:b1]
      opt :c, aliases: [:c1, :c2]
      conflict :a, :c
    }    
    
    def func1(options={})
      FUNC1_OPTIONS.parse options
    end

    def func2(options={})
      FUNC2_OPTIONS.parse options
    end

  end

  def test_define
    assert_same OptionalArgument::Store, Foo::FUNC1_OPTIONS.superclass
  end

  def test_autonyms
    assert_equal [:full_name, :favorite], Foo::FUNC1_OPTIONS.autonyms
    assert_equal [:a, :b, :c], Foo::FUNC2_OPTIONS.autonyms
    assert_not_same Foo::FUNC1_OPTIONS.autonyms, Foo::FUNC1_OPTIONS.autonyms
    assert_not_same Foo::FUNC2_OPTIONS.autonyms, Foo::FUNC2_OPTIONS.autonyms
  end

  def test_names
    assert_equal({name: :full_name, fullname: :full_name, full_name: :full_name, favorite: :favorite}, Foo::FUNC1_OPTIONS.names)
    assert_equal({a: :a, b: :b, b1: :b, c: :c, c1: :c, c2: :c}, Foo::FUNC2_OPTIONS.names)
    assert_not_same Foo::FUNC1_OPTIONS.names, Foo::FUNC1_OPTIONS.names
    assert_not_same Foo::FUNC2_OPTIONS.names, Foo::FUNC2_OPTIONS.names
  end

  def test_func1
    foo = Foo.new

    assert_raises OptionalArgument::MalformedOptionsError do
      foo.func1 
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      foo.func1 favorite: true
    end

    ret = foo.func1 name: 'John'
    
    assert_instance_of Foo::FUNC1_OPTIONS, ret
    assert_equal 'John', ret.name
    assert_equal 'Ruby', ret.favorite

    ret = foo.func1 favorite: 'Scala', name: nil
    assert_equal 'Scala', ret.favorite
  end

  def test_func2
    foo = Foo.new
    ret = foo.func2

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
      foo.func2 a2: true
    end

    assert_raises OptionalArgument::KeyConflictError do
      foo.func2 a: true, c: true
    end

    assert_raises OptionalArgument::KeyConflictError do
      foo.func2 a: true, c: true, b: true
    end

    assert_raises OptionalArgument::KeyConflictError do
      foo.func2 a: true, c2: true, b: true
    end
  end

end