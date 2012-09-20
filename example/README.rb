$VERBOSE = true

require_relative '../lib/optionalargument'

class Foo

  FUNC_OPTION = OptionalArgument.define do
    opt :a, default: ':)', aliases: [:b, :c]
    opt :f, must: true
  end

  p FUNC_OPTION.ancestors

  def func(options={})
    opts = FUNC_OPTION.parse(options)
    if opts.a?
      p opts.a
    end
  end

end

foo = Foo.new
foo.func b: 9, f: 7
