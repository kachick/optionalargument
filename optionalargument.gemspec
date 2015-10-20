# coding: us-ascii

lib_name = 'optionalargument'.freeze
require "./lib/#{lib_name}/version"

Gem::Specification.new do |gem|
  # specific

  gem.description   = %q{Revenge of the Hash options}

  gem.summary       = gem.description.dup
  gem.homepage      = "http://kachick.github.com/#{lib_name}/"
  gem.license       = 'MIT'
  gem.name          = lib_name.dup
  gem.version       = OptionalArgument::VERSION.dup

  gem.required_ruby_version = '>= 2.1'

  gem.add_runtime_dependency 'keyvalidatable', '~> 0.0.5'
  gem.add_runtime_dependency 'validation', '~> 0.0.7'

  gem.add_development_dependency 'yard', '>= 0.8.7.6', '< 0.9'
  gem.add_development_dependency 'rake', '>= 10', '< 20'
  gem.add_development_dependency 'bundler', '>= 1.10', '< 2'
  gem.add_development_dependency 'test-unit', '>= 3.1.1', '< 4'

  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end
