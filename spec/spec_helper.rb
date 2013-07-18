$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'
require 'resque_scheduler'
require 'resque_spec/scheduler'
require 'timecop'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

RSpec.configure do |config|
end
