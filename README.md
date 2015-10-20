optionalargument
=================

[![Build Status](https://secure.travis-ci.org/kachick/optionalargument.png)](http://travis-ci.org/kachick/optionalargument)
[![Gem Version](https://badge.fury.io/rb/optionalargument.png)](http://badge.fury.io/rb/optionalargument)
[![Dependency Status](https://gemnasium.com/kachick/optionalargument.svg)](https://gemnasium.com/kachick/optionalargument)

Description
-----------

DSL for method-arguments checker

Features
--------

* Flexible and readable definitions
* Strict parser for key combinations
* Key compatible for Symbol<->String
* Validate and coerce values
* You can use parsed options as Struct

Usage
-----

You can mix following features :)  
Clean up `DEFUALT_OPTIONS.merge(options)` and annoying validations!

### Parser for arguments

```ruby
require 'optionalargument'

class Foo
  def func(options={})
    opts = OptionalArgument.parse options do
      opt :a, must: true
      opt :b
    end
    
    p opts.a
    p opts.b?
    p opts.b
  end
end

foo = Foo.new
foo.func a: 1           #=> opts.a => 1, opts.b? => false, opts.b => nil
foo.func a: 1, "b" => 2 #=> opts.a => 1, opts.b? => true, opts.b => 2
foo.func "b" => 2       #=> Error (`a` is must, but not passed)
foo.func a:1, c: 3      #=> Error (`c` is not defined)
```

### Key combinations

```ruby
OptArg = OptionalArgument.define {
  opt :a
  opt :b
  conflict :a, :b
  opt :c, requirements: [:b, :d]
  opt :d, aliases: [:d2, :d3]
  opt :e, deprecateds: [:e2, :e3]
}

OptArg.parse(a: 1, b: 1) #=> Error: conflict conbination thrown: a, b'
OptArg.parse(c: 1)       #=> Error: `c` requires  `b` and `d`
OptArg.parse(d2: 1).d3   #=> 1
OptArg.parse(e2: 1).e3   #=> 1 with warning "`e2` is deprecated, use `e`"
```

### Validate and coerce value

```ruby
OptArg = OptionalArgument.define {
  opt :x, condition: 3..5
  opt :y, condition: AND(Float, 3..5)
  opt :z, adjuster: ->arg{Float arg}
}

OptArg.parse x: 5       #=> pass : 5 is sufficient for 3..5
OptArg.parse x: 6       #=> Error: 6 is deficient for 3..5
OptArg.parse y: 5       #=> Error: 5 is deficient for Float
OptArg.parse y: 5.0     #=> pass : 5.0 is sufficient for 3..5 and Float
OptArg.parse(z: '1').z  #=> 1.0  : casted under adjuster
```

### Handle default values

```ruby
OptArg = OptionalArgument.define {
  opt :a
  opt :b, default: 'This is a default value'
}

OptArg.parse(a: 1).b  #=> 'This is a default value'
```

### Switch error

```ruby
OptArg = OptionalArgument.define {
  opt :a
}

OptArg.parse({b: 1}, exception: ArgumentError) #=> ArgumentError
OptArg.parse({b: 1}, exception: KeyError)      #=> KeyError
```

This library helps you the building checkers for arguments. But normally behaves so relax. Because [Builtin features are designed by relax parsing for unknown options](http://www.ruby-forum.com/topic/4402711#1064528).

```ruby
OptArg = OptionalArgument.define {
  opt :known, must: true
}

opts = OptArg.parse(
         {known: 1, unknown: 2},
         defined_only: false)    #=> pass
```

Requirements
-------------

* Ruby - [1.9.3 or later](http://travis-ci.org/#!/kachick/optionalargument)

Install
-------

```bash
gem install optionalargument
```

Link
----

* [Home](http://kachick.github.com/optionalargument/)
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
