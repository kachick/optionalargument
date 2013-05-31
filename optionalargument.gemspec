Gem::Specification.new do |gem|
  # specific

  gem.description   = %q{Flexible and easy deal hash arguments.}

  gem.summary       = gem.description.dup
  gem.homepage      = 'http://kachick.github.com/optionalargument/'
  gem.license       = 'MIT'
  gem.name          = 'optionalargument'
  gem.version       = '0.0.3.3'

  gem.required_ruby_version = '>= 1.9.2'

  gem.add_runtime_dependency 'keyvalidatable', '~> 0.0.5'
  gem.add_runtime_dependency 'validation', '~> 0.0.5'

  gem.add_development_dependency 'yard', '>= 0.8.6.1', '< 2'
  gem.add_development_dependency 'rake', '>= 10', '< 20'
  gem.add_development_dependency 'bundler', '>= 1.3.5', '< 2'

  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']
end