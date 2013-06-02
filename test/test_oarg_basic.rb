require_relative 'helper'

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

class Test_OptionalArgument_Requirements < Test::Unit::TestCase

  OptArg = OptionalArgument.define {
    opt :a
    opt :b, requirements: [:a, :d]
    opt :c
    opt :d
  }

  def test_parse_error
    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg.parse b:1
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg.parse a: 1, b: 1
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg.parse a: 1, b: 1, c: 1
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg.parse b:1 , c: 1
    end

    assert_raises OptionalArgument::MalformedOptionsError do
      OptArg.parse b:1 , d: 1
    end
  end

  def test_parse_passing
    assert_instance_of OptArg, OptArg.parse(a: 1)
    assert_instance_of OptArg, OptArg.parse(c: 1)
    assert_instance_of OptArg, OptArg.parse(d: 1)
    assert_instance_of OptArg, OptArg.parse(a: 1, d: 1)
    assert_instance_of OptArg, OptArg.parse(a: 1, b: 1 ,d: 1)
  end

  def test_defining_error
    assert_raises ArgumentError do
      OptionalArgument.define {
        opt :a
        opt :b, requirements: [:a, :d, :e]
        opt :c
        opt :d
      }
    end

    assert_raises ArgumentError do
      OptionalArgument.define {
        opt :a
        opt :b, requirements: :a
        opt :c
        opt :d
      }
    end
  end

end