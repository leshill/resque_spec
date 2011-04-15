require 'resque_spec/ext'
require 'resque_spec/helpers'
require 'resque_spec/matchers'

module ResqueSpec
  extend self

  attr_accessor :inline

  def dequeue(queue_name, klass, *args)
    queue_by_name(queue_name).delete_if do |job|
      job[:class] == klass.to_s && args.empty? || job[:args] == args
    end
  end

  def enqueue(queue_name, klass, *args)
    store(queue_name, klass, { :class => klass.to_s, :args => args })
  end

  def queue_by_name(name)
    queues[name]
  end

  def queue_for(klass)
    queue_by_name(queue_name(klass))
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
  end

  private

  def name_from_instance_var(klass)
    klass.instance_variable_get(:@queue)
  end

  def name_from_queue_accessor(klass)
    klass.respond_to?(:queue) and klass.queue
  end

  def store(queue_name, klass, payload)
    if inline
      klass.send(:perform, *payload[:args])
    else
      queue_by_name(queue_name) << payload
    end
  end
end

config = RSpec.configuration
config.include ResqueSpec::Helpers

World(ResqueSpec::Helpers) if defined?(World)
