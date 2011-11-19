require 'resque'

module Resque
  class Job
    def self.create(queue, klass, *args)
      raise ::Resque::NoQueueError.new("Jobs must be placed onto a queue.") if !queue
      raise ::Resque::NoClassError.new("Jobs must be given a class.") if klass.to_s.empty?
      ResqueSpec.enqueue(queue, klass, *args)
    end

    def self.destroy(queue, klass, *args)
      raise ::Resque::NoQueueError.new("Jobs must have been placed onto a queue.") if !queue
      raise ::Resque::NoClassError.new("Jobs must have been given a class.") if klass.to_s.empty?

      old_count = ResqueSpec.queue_by_name(queue).size

      ResqueSpec.dequeue(queue, klass, *args)

      old_count - ResqueSpec.queue_by_name(queue).size
    end
  end

  def enqueue(klass, *args)
    enqueue_to(queue_from_class(klass), klass, *args)
  end

  def enqueue_to(queue, klass, *args)
    if ResqueSpec.inline
      return if run_before_enqueue(klass, *args)
      run_after_enqueue(klass, *args)
      Job.create(queue, klass, *args)
    else
      return if run_before_enqueue(klass, *args)
      Job.create(queue, klass, *args)
      run_after_enqueue(klass, *args)
    end
  end

  private

  def run_after_enqueue(klass, *args)
    Plugin.after_enqueue_hooks(klass).each do |hook|
      klass.send(hook, *args)
    end
  end

  def run_before_enqueue(klass, *args)
    before_hooks = Plugin.before_enqueue_hooks(klass).collect do |hook|
      klass.send(hook, *args)
    end
    before_hooks.any? { |result| result == false }
  end
end
