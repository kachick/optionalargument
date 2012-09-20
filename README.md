optionalargument
=================

Description
-----------

"like keyword arguments"++

Features
--------

* Definition so flexible.
* Can easy use the parsed object.
* Pure Ruby :)

Usage
-----

### Overview

```ruby
require 'optionalargument'

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

foo.func(a: 1)              #=> Error: shortage option parameter: c
opts = foo.func(a: 1,
                c: 3)   
p opts                      #=> #<Foo::FUNC_OPTIONS: a=1, c=3>
p opts.a?                   #=> true
p opts.a                    #=> 1
p opts.b?                   #=> true
p opts.b                    #=> ":)"
p opts.d?                   #=> false
p opts.d                    #=> nil

foo.func(a: 1, c: 3, e: 5)  #=> Error: conflict conbination thrown: a, e
opts = foo.func(c: 3,
                e: 5,
                d2: 4) 
p opts                      #=> #<Foo::FUNC_OPTIONS: c=3, e=5, d=4>
p opts.d3?                  #=> true
p opts.d3                   #=> 4
```

Requirements
-------------

* Ruby - [1.9.2 or later](http://travis-ci.org/#!/kachick/optionalargument)
* [keyvalidatable - 0.0.3](https://github.com/kachick/keyvalidatable)

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
See the file LICENSE for further details.

