$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'timecop'
require 'pry'
require 'resque'
require 'resque_spec'

# Schedule does not yet work with 2.0
if Resque.respond_to? :reserve
  require 'resque_scheduler'
  require 'resque_spec/scheduler'
end

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
end
