$VERBOSE = true

require_relative '../lib/optionalargument'

class Foo

  FUNC_OPTIONS = OptionalArgument.define do
    opt :a
    opt :b, default: ':)'
    opt :c, must: true
    opt :d, aliases: [:d2, :d3]
    opt :e
    conflict :a, :e
  end

  def func(options={})
    opts = FUNC_OPTIONS.parse(options)
  end

end

foo = Foo.new

#foo.func(a: 1)             #=> Error: shortage option parameter: c
opts = foo.func(a: 1,
                c: 3)   
p opts                      #=> #<Foo::FUNC_OPTIONS: a=1, c=3>
p opts.a?                   #=> true
p opts.a                    #=> 1
p opts.b?                   #=> true
p opts.b                    #=> ":)"
p opts.d?                   #=> false
p opts.d                    #=> nil

#foo.func(a: 1, c: 3, e: 5) #=> Error: conflict conbination thrown: a, e
opts = foo.func(c: 3,
                e: 5,
                d2: 4) 
p opts                      #=> #<Foo::FUNC_OPTIONS: c=3, e=5, d=4>
p opts.d3?                  #=> true
p opts.d3                   #=> 4
