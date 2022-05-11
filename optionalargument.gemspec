# coding: us-ascii
# frozen_string_literal: true

lib_name = 'optionalargument'
repository_url = "https://github.com/kachick/#{lib_name}"

require_relative "./lib/#{lib_name}/version"

Gem::Specification.new do |gem|
  gem.summary       = %q{Building method arguments checker with DSL}
  gem.description   = <<-'DESCRIPTION'
    Building method arguments checker with DSL
  DESCRIPTION
  gem.homepage      = repository_url
  gem.license       = 'MIT'
  gem.name          = lib_name
  gem.version       = OptionalArgument::VERSION

  gem.metadata = {
    'documentation_uri' => 'https://kachick.github.io/optionalargument/',
    'homepage_uri'      => repository_url,
    'source_code_uri'   => repository_url,
    'bug_tracker_uri'   => "#{repository_url}/issues"
  }

  gem.required_ruby_version = Gem::Requirement.new('>= 2.7.0')

  gem.add_runtime_dependency 'eqq', '>= 0.0.4', '< 0.1.0'

  # common

  gem.authors       = ['Kenichi Kamiya']
  gem.email         = ['kachick1+ruby@gmail.com']
  git_managed_files = `git ls-files`.lines.map(&:chomp)
  might_be_parsing_by_tool_as_dependabot = git_managed_files.empty?
  base_files = Dir['README*', '*LICENSE*',  'lib/**/*', 'sig/**/*'].uniq
  files = might_be_parsing_by_tool_as_dependabot ? base_files : (base_files & git_managed_files)

  unless might_be_parsing_by_tool_as_dependabot
    if files.grep(%r!\A(?:lib|sig)/!).size < 5
      raise "obvious mistaken in packaging files, looks shortage: #{files.inspect}"
    end
  end

  gem.files         = files
  gem.require_paths = ['lib']
end
