require 'resque'

module Resque
  class Job
    def self.create(queue, klass, *args)
      raise ::Resque::NoQueueError.new("Jobs must be placed onto a queue.") if !queue
      raise ::Resque::NoClassError.new("Jobs must be given a class.") if klass.to_s.empty?
      ResqueSpec.queues[queue] << {:klass => klass.to_s, :args => args}
    end

    def self.destroy(queue, klass, *args)
      raise ::Resque::NoQueueError.new("Jobs must have been placed onto a queue.") if !queue
      raise ::Resque::NoClassError.new("Jobs must have been given a class.") if klass.to_s.empty?

      old_count = ResqueSpec.queues[queue].size

      if args.empty?
        ResqueSpec.queues[queue].delete_if{ |job| job[:klass] == klass.to_s }
      else
        ResqueSpec.queues[queue].delete_if{ |job| job[:klass] == klass.to_s and job[:args].to_a == args.to_a }
      end

      old_count - ResqueSpec.queues[queue].size
    end
  end
end
