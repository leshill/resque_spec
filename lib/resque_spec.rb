require 'resque_spec/ext'
require 'resque_spec/helpers'
require 'resque_spec/matchers'

module ResqueSpec
  extend self

  attr_accessor :inline
  attr_accessor :disable_ext

  def dequeue(queue_name, klass, *args)
    queue_by_name(queue_name).delete_if do |job|
      job[:class] == klass.to_s && args.empty? || job[:args] == args
    end
  end

  def enqueue(queue_name, klass, *args)
    perform_or_store(queue_name, :class => klass.to_s, :args => args)
  end

  def perform_next(queue_name)
    perform(queue_name, queue_by_name(queue_name).shift)
  end

  def perform_all(queue_name)
    queue = queue_by_name(queue_name)
    until queue.empty?
      perform(queue_name, queue.shift)
    end
  end

  def pop(queue_name)
    return unless payload = queue_by_name(queue_name).shift
    new_job(queue_name, payload)
  end

  def queue_by_name(name)
    queues[name.to_s]
  end

  def queue_for(klass)
    queue_by_name(queue_name(klass))
  end

  def peek(queue_name, start = 0, count = 1)
    queue_by_name(queue_name).slice(start, count)
  end

  def queue_name(klass)
    if klass.is_a?(String)
      klass = Kernel.const_get(klass) rescue nil
    end

    name_from_instance_var(klass) or
      name_from_queue_accessor(klass) or
        raise ::Resque::NoQueueError.new("Jobs must be placed onto a queue.")
  end

  def queues
    @queues ||= Hash.new {|h,k| h[k] = []}
  end

  def reset!
    queues.clear
    self.inline = false
  end

  private

  def name_from_instance_var(klass)
    klass.instance_variable_get(:@queue)
  end

  def name_from_queue_accessor(klass)
    klass.respond_to?(:queue) and klass.queue
  end

  def new_job(queue_name, payload)
    Resque::Job.new(queue_name, payload_with_string_keys(payload))
  end

  def perform(queue_name, payload)
    job = new_job(queue_name, payload)
    begin
      job.perform
    rescue Object => e
      job.fail(e)
    end
  end

  def perform_or_store(queue_name, payload)
    if inline
      perform(queue_name, payload)
    else
      store(queue_name, payload)
    end
  end

  def store(queue_name, payload)
    queue_by_name(queue_name) << payload
  end

  def payload_with_string_keys(payload)
    {
      'class' => payload[:class],
      'args' => decode(encode(payload[:args])),
      'stored_at' => payload[:stored_at]
    }
  end

  def encode(object)
    Resque.encode(object)
  end

  def decode(object)
    Resque.decode(object)
  end
end

config = RSpec.configuration
config.include ResqueSpec::Helpers
