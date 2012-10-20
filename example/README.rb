$VERBOSE = true

require_relative '../lib/optionalargument'

class Foo

  OptArg = OptionalArgument.define {
    opt :a
    opt :b, default: ':)'
    opt :c, must: true
    opt :d, aliases: [:d2, :d3]
    opt :e
    conflict :a, :e
  }

  def func(options={})
    opts = OptArg.parse(options)
  end

end

foo = Foo.new

#foo.func(a: 1)             #=> Error: shortage option parameter: c
opts = foo.func a: 1, c: 3
p opts                      #=> #<optargs: a=1, c=3, b=":)">
p opts.a?                   #=> true
p opts.a                    #=> 1
p opts.b?                   #=> true
p opts.b                    #=> ":)"
p opts.d?                   #=> false
p opts.d                    #=> nil

#foo.func(a: 1, c: 3, e: 5) #=> Error: conflict conbination thrown: a, e
opts = foo.func c: 3, e: 5, d2: 4
p opts                      #=> #<optargs: c=3, e=5, d=4, b=":)">
p opts.d3?                  #=> true
p opts.d3                   #=> 4
p opts.to_h                 #=> {:c=>3, :e=>5, :d=>4, :b=>":)"}

OPTARG = OptionalArgument.define {
  opt :x, condition: 3..5
  opt :y, condition: AND(Float, 3..5)
  opt :z, adjuster: ->arg{Float arg}
}

OPTARG.parse x: 5            #=> pass : 5 is sufficient for 3..5
#OPTARG.parse x: 6           #=> error: 6 is deficient for 3..5 
#OPTARG.parse y: 5           #=> error: 5 is deficient for Float
OPTARG.parse y: 5.0          #=> pass : 5.0 is sufficient for 3..5 and Float
OPTARG.parse(z: '1').z       #=> 1.0  : casted under adjuster
