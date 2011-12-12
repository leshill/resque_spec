require 'resque'
require 'spec'

module ResqueSpec
  extend self

  def perform_all(queue_name)
    queue = queue_by_name(queue_name)
    until queue.empty?
      perform(queue_name, queue.shift)
    end
  end

  def queue_by_name(name)
    queues[name]
  end

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

  def new_job(queue_name, payload)
    ::Resque::Job.new(queue_name, payload_with_string_keys(payload))
  end

  def perform(queue_name, payload)
    job = new_job(queue_name, payload)
    job.perform
  end

  def payload_with_string_keys(payload)
    {
      'class' => payload[:klass],
      'args' => payload[:args]
    }
  end

  def name_from_instance_var(klass)
    klass.instance_variable_get(:@queue)
  end

  def name_from_queue_accessor(klass)
    klass.respond_to?(:queue) and klass.queue
  end
end

Resque.extend(ResqueSpec::Resque)

Spec::Matchers.define :have_queued do |*expected_args|
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
    "have queued arguments"
  end
end

