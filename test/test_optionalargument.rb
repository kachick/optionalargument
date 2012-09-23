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


class Test_OptionalArgument_BasicAPI < Test::Unit::TestCase

  OARG = OptionalArgument.define {
    opt :a
    opt :b, aliases: [:b2]
    opt :c, default: :C
  }

  def test_to_strings
    oarg = OARG.parse a: 'A'
    assert_instance_of String, oarg.inspect
    assert_equal oarg.inspect, oarg.to_s
    assert_not_same oarg.inspect, oarg.to_s
    assert_not_same oarg.to_s, oarg.to_s
    assert_equal '#<optargs: a="A", c=:C>', oarg.inspect
  end

  def test_class_method_scope
    assert_same false, OARG.respond_to?(:new)
    assert_same true, OARG.respond_to?(:new, true)

    assert_raises NoMethodError do
      OARG.new({})
    end

    assert ([:for_options, :for_pairs, :parse, :autonym_for_name, :autonym_for, :autonyms] - OARG.public_methods).empty?

    assert ([:add_option, :opt, :on, :add_conflict] - OARG.private_methods).empty?
  end

  def test_fix_at_onetime
    store = OptionalArgument.define {
      opt :foo
    }
    assert_raises RuntimeError do
      store.__send__ :opt, :bar
    end
  end

  def test_reject_noassigned
    assert_raises RuntimeError do
      OptionalArgument.define {
      }
    end
  end

  def test_compare_eql?
    oarg = OARG.parse a: 1
    
    assert_raises NoMethodError do
      oarg.eql? BasicObject.new
    end

    assert_same false, oarg.eql?(Object.new)
    assert_same true, oarg.eql?(OARG.parse a: 1)
    assert_same false, oarg.eql?(OARG.parse a: 1.0)
    assert_same false, oarg.eql?(OARG.parse({}))
    assert_same false, oarg.eql?(OARG.parse a: 1, b: nil)

    assert_same :MATCH, {oarg => :MATCH}.fetch(OARG.parse a: 1)
  end

  def test_compare
    oarg = OARG.parse a: 1
    
    assert_raises NoMethodError do
      oarg === BasicObject.new
    end

    assert_same false, oarg == Object.new
    assert_same true, oarg == OARG.parse(a: 1)
    assert_same true, oarg == OARG.parse(a: 1.0)
    assert_same false, oarg == OARG.parse({})
    assert_same false, oarg == OARG.parse(a: 1, b: nil)
  end

  def test_to_h
    oarg = OARG.parse a: 'A'
    assert_equal({a: 'A', c: :C}, oarg.to_h)
    assert_not_same oarg.to_h, oarg.to_h
  end

  def test_each_pair
    oarg = OARG.parse a: 'A', b2: 'B2'

    yret = oarg.each_pair {}
    assert_same oarg, yret
    
    yargs = []
    oarg.each_pair do |k, v|
      yargs << [k, v]
    end

    assert_equal [[:a, 'A'], [:b, 'B2'], [:c, :C]], yargs

    enum = oarg.each_pair
    assert_instance_of Enumerator, enum
    assert_equal [:a, 'A'], enum.next
    assert_equal [:b, 'B2'], enum.next
    assert_equal [:c, :C], enum.next
    assert_raises StopIteration do
      enum.next
    end
  end

end

class Test_OptionalArgument_ValidateValues < Test::Unit::TestCase

  OARG = OptionalArgument.define {
    opt 'included space :)'
    opt :with_cond, condition: AND(/\AFOO\z/, Symbol)
    opt :with_adj, adjuster: ->arg{arg.to_sym}
    opt :with_cond_adj, condition: AND(/\AFOO\z/, Symbol),
                        adjuster: ->arg{arg.to_sym}
  }

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
