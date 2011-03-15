require 'resque_spec/resque_spec'
require 'resque_spec/resque_scheduler_spec'
require 'resque_spec/helpers'
require 'resque_spec/matchers'

config = RSpec.configuration
config.include ResqueSpec::Helpers

World(ResqueSpec::Helpers) if defined?(World)
