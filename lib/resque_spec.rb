require 'resque_spec/resque_spec'
require 'resque_spec/resque_scheduler_spec'
require 'resque_spec/helpers'

config = RSpec.configuration
config.include ResqueSpec::Helpers
