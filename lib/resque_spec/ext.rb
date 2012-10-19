require 'resque'

module Resque
  class Job
    class << self
      alias :create_without_resque_spec :create
      alias :destroy_without_resque_spec :destroy
    end

    def self.create(queue, klass, *args)
      return create_without_resque_spec(queue, klass, *args) if ResqueSpec.disable_ext

      raise ::Resque::NoQueueError.new("Jobs must be placed onto a queue.") if !queue
      raise ::Resque::NoClassError.new("Jobs must be given a class.") if klass.to_s.empty?
      ResqueSpec.enqueue(queue, klass, *args)
    end

    def self.destroy(queue, klass, *args)
      return destroy_without_resque_spec(queue, klass, *args) if ResqueSpec.disable_ext

      raise ::Resque::NoQueueError.new("Jobs must have been placed onto a queue.") if !queue
      raise ::Resque::NoClassError.new("Jobs must have been given a class.") if klass.to_s.empty?

      old_count = ResqueSpec.queue_by_name(queue).size

      ResqueSpec.dequeue(queue, klass, *args)

      old_count - ResqueSpec.queue_by_name(queue).size
    end
  end

  alias :enqueue_without_resque_spec :enqueue
  alias :enqueue_to_without_resque_spec :enqueue_to if Resque.respond_to? :enqueue_to
  alias :reserve_without_resque_spec :reserve
  alias :peek_without_resque_spec :peek
  alias :size_without_resque_spec :size

  def enqueue(klass, *args)
    return enqueue_without_resque_spec(klass, *args) if ResqueSpec.disable_ext

    enqueue_to(queue_from_class(klass), klass, *args)
  end

  def enqueue_to(queue, klass, *args)
    return enqueue_to_without_resque_spec(queue, klass, *args) if ResqueSpec.disable_ext

    if ResqueSpec.inline
      return if run_before_enqueue(klass, *args)
      run_after_enqueue(klass, *args)
      Job.create(queue, klass, *args)
    else
      return if run_before_enqueue(klass, *args)
      Job.create(queue, klass, *args)
      run_after_enqueue(klass, *args)
      true
    end
  end

  def peek(queue, start = 0, count = 1)
    return peek_without_resque_spec(queue, start, count) if ResqueSpec.disable_ext
    ResqueSpec.peek(queue, start, count).map do |job|
      job.inject({}) { |a, (k, v)| a[k.to_s] = v; a }
    end
  end

  def reserve(queue_name)
    return reserve_without_resque_spec(queue_name) if ResqueSpec.disable_ext

    ResqueSpec.pop(queue_name)
  end

  def size(queue_name)
    return size_without_resque_spec(queue_name) if ResqueSpec.disable_ext

    ResqueSpec.queue_by_name(queue_name).count
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
