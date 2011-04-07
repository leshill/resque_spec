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

      old_count = ResqueSpec.queues[queue].size

      ResqueSpec.dequeue(queue, klass, *args)

      old_count - ResqueSpec.queues[queue].size
    end
  end
end
