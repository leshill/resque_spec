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

  s.require_path = "lib"

  s.files = Dir.glob("lib/**/*") + %w(LICENSE README.md Rakefile)

  # s.add_runtime_dependency('resque', ['>= 1.15.0'])
  s.add_runtime_dependency('resque', ['>= 1.15.0'])
  s.add_runtime_dependency('rspec', ['>= 2.5.0'])
  if RUBY_VERSION.match /1\.9/
    s.add_development_dependency('ruby-debug19')
  else
    s.add_development_dependency('ruby-debug')    
  end
  s.add_development_dependency('timecop')
end

