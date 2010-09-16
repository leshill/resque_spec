require 'rspec'
require 'resque'

module ResqueSpec
  extend self

  def in_queue?(klass, *args)
    queue_for(klass).any? {|entry| entry[:klass] == klass && entry[:args] == args}
  end

  def queue_for(klass)
    queues[queue_name(klass)]
  end

  def queue_name(klass)
    name_from_instance_var(klass) or
      name_from_queue_accessor(klass) or
      raise ::Resque::NoQueueError.new("Jobs must be placed onto a queue.")
  end

  def queue_size(klass)
    queue_for(klass).size
  end

  def queues
    @queues ||= Hash.new {|h,k| h[k] = []}
  end

  def reset!
    queues.clear
  end

  module Resque
    def enqueue(klass, *args)
      ResqueSpec.queue_for(klass) << {:klass => klass, :args => args}
    end
  end

  private

  def name_from_instance_var(klass)
    klass.instance_variable_get(:@queue)
  end

  def name_from_queue_accessor(klass)
    klass.respond_to?(:queue) and klass.queue
  end
end

Resque.extend(ResqueSpec::Resque)

RSpec::Matchers.define :have_queued do |*expected_args|
  match do |actual|
    ResqueSpec.in_queue?(actual, *expected_args)
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have [#{expected_args.join(', ')}] queued"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have [#{expected_args.join(', ')}] queued"
  end

  description do
    "have queued arguments of [#{expected_args.join(', ')}]"
  end
end

RSpec::Matchers.define :have_queue_size_of do |size|
  match do |actual|
    ResqueSpec.queue_size(actual) == size
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have #{size} entries queued"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have #{size} entries queued"
  end

  description do
    "have a queue size of #{size}"
  end
end
