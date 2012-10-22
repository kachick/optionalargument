optionalargument
=================

Description
-----------

Flexible and easy deal hash arguments.

Features
--------

* Definition so flexible and strict parse the key-value options.
* Parsed objects can use as struct like API.
* Pure Ruby :)

Usage
-----

### What keys do you want? Declare it.

```ruby
require 'optionalargument'

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

foo.func(a: 1)              #=> Error: shortage option parameter: c
opts = foo.func(a: 1,
                c: 3)   
p opts                      #=> #<optargs: a=1, c=3, b=":)">
p opts.a?                   #=> true
p opts.a                    #=> 1
p opts.b?                   #=> true
p opts.b                    #=> ":)"
p opts.d?                   #=> false
p opts.d                    #=> nil
p opts.to_h                 #=> {:c=>3, :e=>5, :d=>4, :b=>":)"}

foo.func(a: 1, c: 3, e: 5)  #=> Error: conflict conbination thrown: a, e
opts = foo.func(c: 3,
                e: 5,
                d2: 4) 
p opts                      #=> #<optargs: c=3, e=5, d=4, b=":)">
p opts.d3?                  #=> true
p opts.d3                   #=> 4
```

### What value do you want? Declare It.

```ruby
OPTARG = OptionalArgument.define {
  opt :x, condition: 3..5
  opt :y, condition: AND(Float, 3..5)
  opt :z, adjuster: ->arg{Float arg}
}

OPTARG.parse x: 5            #=> pass : 5 is sufficient for 3..5
OPTARG.parse x: 6            #=> error: 6 is deficient for 3..5 
OPTARG.parse y: 5            #=> error: 5 is deficient for Float
OPTARG.parse y: 5.0          #=> pass : 5.0 is sufficient for 3..5 and Float
OPTARG.parse(z: '1').z       #=> 1.0  : casted under adjuster
```

Of course, you can mix these options :)

Requirements
-------------

* Ruby - [1.9.2 or later](http://travis-ci.org/#!/kachick/optionalargument)
* keyvalidatable - [0.0.5](https://github.com/kachick/keyvalidatable)
* validation - [0.0.3](https://github.com/kachick/validation)

Install
-------

```bash
$ gem install optionalargument
```

Build Status
-------------

[![Build Status](https://secure.travis-ci.org/kachick/optionalargument.png)](http://travis-ci.org/kachick/optionalargument)

Link
----

* [code](https://github.com/kachick/optionalargument)
* [API](http://kachick.github.com/optionalargument/yard/frames.html)
* [issues](https://github.com/kachick/optionalargument/issues)
* [CI](http://travis-ci.org/#!/kachick/optionalargument)
* [gem](https://rubygems.org/gems/optionalargument)

License
--------

The MIT X11 License  
Copyright (c) 2012 Kenichi Kamiya  
See MIT-LICENSE for further details.

