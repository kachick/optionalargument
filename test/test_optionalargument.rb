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



class Test_OptionalArgument_API < Test::Unit::TestCase

  OARG = OptionalArgument.define {
    opt :a
    opt 'included space :)'
    opt :with_cond, condition: AND(/\AFOO\z/, Symbol)
    opt :with_adj, adjuster: ->arg{arg.to_sym}
    opt :with_cond_adj, condition: AND(/\AFOO\z/, Symbol),
                        adjuster: ->arg{arg.to_sym}
  }

  def test_to_strings
    oarg = OARG.parse a: 'A'
    assert_instance_of String, oarg.inspect
    assert_equal oarg.inspect, oarg.to_s
    assert_not_same oarg.inspect, oarg.to_s
    assert_not_same oarg.to_s, oarg.to_s
    assert oarg.to_s.include?('_API::OARG: a="A">')
  end

  def test_strange_key
    oarg = OARG.parse :'included space :)' => 123
    assert oarg.public_methods.include?(:'included space :)')
    assert_same 123, oarg[:'included space :)']
    assert_same 123, oarg.public_send(:'included space :)')
  end

  def test_with_cond
    oarg = OARG.parse with_cond: :FOO
    assert_same :FOO, oarg.fetch_by_with_cond
    assert_same :FOO, oarg.with_cond
    assert_same true, oarg.with_with_cond?
    assert_same true, oarg.with_cond?

    assert_raises Validation::InvalidWritingError do
      OARG.parse with_cond: 'FOO'
    end

    assert_raises Validation::InvalidWritingError do
      OARG.parse with_cond: :BAR
    end
  end

  def test_with_adj
    oarg = OARG.parse with_adj: 'foo'
    assert_not_equal 'foo', oarg.fetch_by_with_adj
    assert_same :foo, oarg.fetch_by_with_adj

    assert_raises Validation::InvalidAdjustingError do
      OARG.parse with_adj: Object.new
    end
  end

  def test_with_cond_adj
    oarg = OARG.parse with_cond_adj: 'FOO'
    assert_not_equal 'FOO', oarg.fetch_by_with_cond_adj
    assert_same :FOO, oarg.fetch_by_with_cond_adj

    assert_raises Validation::InvalidAdjustingError do
      OARG.parse with_cond_adj: Object.new
    end

    assert_raises Validation::InvalidWritingError do
      OARG.parse with_cond_adj: 'foo'
    end
  end

  OARG2 = OptionalArgument.define {
    opt :with_cond_default, condition: AND(/\AFOO\z/, Symbol),
                            default: 'FOO'
  }

  def test_with_cond_default
    assert_raises Validation::InvalidWritingError do
      OARG2.parse({})
    end

    oarg = OARG2.parse with_cond_default: :FOO
    assert_not_equal 'FOO', oarg.fetch_by_with_cond_default
    assert_same :FOO, oarg.fetch_by_with_cond_default
  end


  OARG3 = OptionalArgument.define {
    opt :with_cond_adj_default, condition: AND(/\AFOO\z/, Symbol),
                                default: 'FOO',
                                adjuster: ->arg{arg.to_sym}
  }

  def test_with_cond_adj_default
    oarg = OARG3.parse({})
    assert_not_equal 'FOO', oarg.fetch_by_with_cond_adj_default
    assert_same :FOO, oarg.fetch_by_with_cond_adj_default
  end

end
