lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require "resque_spec/version"

Gem::Specification.new do |s|
  s.required_rubygems_version = '>= 1.3.6'

  s.name = 'resque_spec'
  s.version = ResqueSpec::VERSION
  s.authors = ['Les Hill']
  s.description = 'RSpec matchers for Resque'
  s.summary = 'RSpec matchers for Resque'
  s.homepage = 'http://github.com/leshill/resque_spec'
  s.email = 'leshill@gmail.com'
  s.license = 'MIT'

  s.require_path = "lib"

  s.files = Dir.glob("lib/**/*") + %w(LICENSE README.md Rakefile)

  s.add_runtime_dependency('resque', ['>= 1.26.0'])
  s.add_runtime_dependency('rspec-core', ['>= 3.0.0'])
  s.add_runtime_dependency('rspec-expectations', ['>= 3.0.0'])
  s.add_runtime_dependency('rspec-mocks', ['>= 3.0.0'])
  s.add_development_dependency('resque-scheduler', ['>= 4.3.1'])
  s.add_development_dependency('pry')
  s.add_development_dependency('pry-byebug')
  s.add_development_dependency('timecop')
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', ['>= 3.0.0'])
end
