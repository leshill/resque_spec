$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

begin
  require 'spec'
rescue NameError, LoadError => e
  require 'rspec'
end

require 'resque_spec/scheduler'
require 'timecop'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

rspec_or_spec_configure = (defined? RSpec) ? RSpec : Spec::Runner
rspec_or_spec_configure.configure do |config|
end
