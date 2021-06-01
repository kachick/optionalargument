# coding: us-ascii
# frozen_string_literal: true

$VERBOSE = true

require_relative '../lib/optionalargument'

class Foo
  FuncOptArg = OptionalArgument.define {
    opt :a, must: true
    opt :b
  }

  def func(options={})
    opts = FuncOptArg.parse options
    p opts.a
    p opts.b?
    p opts.b
  end
end

foo = Foo.new
foo.func({a: 1})           #=> opts.a => 1, opts.b? => false, opts.b => nil
foo.func({a: 1, 'b' => 2}) #=> opts.a => 1, opts.b? => true, opts.b => 2

begin
  foo.func({'b' => 2 })    #=> Error (`a` is must, but not passed)
rescue
  p $!
end

begin
  foo.func({a: 1, c: 3})    #=> Error (`c` is not defined)
rescue
  p $!
end
