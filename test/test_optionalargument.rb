require_relative 'helper'

class Test_OptionalArgument < Test::Unit::TestCase

  class Foo

    FUNC_OPTIONS = OptionalArgument.define {
      opt :full_name, must: true, aliases: [:name, :fullname] 
      opt :favorite, default: 'Ruby'
    }
    
    def func(options={})
      FUNC_OPTIONS.parse options
    end

  end

  def test_constructor
    assert_same OptionalArgument::Store, Foo::FUNC_OPTIONS.superclass
    foo = Foo.new
    assert_instance_of Foo::FUNC_OPTIONS, foo.func(name: 'John')
  end

  def test_func
    assert_same OptionalArgument::Store, Foo::FUNC_OPTIONS.superclass
    foo = Foo.new
    assert_instance_of Foo::FUNC_OPTIONS, foo.func(name: 'John')
  end

end
