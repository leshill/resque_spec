begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "resque_spec"
    gem.summary = %{RSpec matchers for Resque}
    gem.description = %{RSpec matchers for Resque}
    gem.email = "leshill@gmail.com"
    gem.homepage = "http://github.com/leshill/resque_spec"
    gem.authors = ["Les Hill"]
    gem.add_dependency "resque", ">= 1.6.0"
    gem.add_dependency "rspec", ">= 2.0.0.beta.12"
    gem.add_development_dependency "jeweler", ">= 1.4.0"
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "resque_spec #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
