Gem::Specification.new do |gem|
  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  gem.summary       = %q{Flexible define and parse keyword like arguments too easy.}
  gem.description   = %q{Flexible define and parse keyword like arguments too easy.}
  gem.homepage      = 'https://github.com/kachick/optionalargument'

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'optionalargument'
  gem.require_paths = ['lib']
  gem.version       = '0.0.3.a'

  gem.required_ruby_version = '>= 1.9.2'

  gem.add_runtime_dependency 'keyvalidatable', '~> 0.0.3'
  gem.add_runtime_dependency 'validation', '~> 0.0.3'

  gem.add_development_dependency 'yard', '~> 0.8'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'bundler'
end

