require 'resque'

module ResqueSpec
  extend self

  def in_queue?(klass, *args)
    options = args.last.is_a?(Hash) ? args.pop : {}
    queue = options[:queue_name] ? queues[options[:queue_name]] : queue_for(klass)
    queue.any? {|entry| entry[:klass].to_s == klass.to_s && entry[:args] == args}
  end

  def queue_for(klass)
    queues[queue_name(klass)]
  end

  def queue_name(klass)
    if klass.is_a?(String)
      klass = Kernel.const_get(klass) rescue nil
    end

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

  private

    def name_from_instance_var(klass)
      klass.instance_variable_get(:@queue)
    end

    def name_from_queue_accessor(klass)
      klass.respond_to?(:queue) and klass.queue
    end

  module Resque
    extend self

    def reset!
      ResqueSpec.reset!
    end

    module Job
      extend self

      def self.included(base)
        base.instance_eval do

          def create(queue, klass, *args)
            raise ::Resque::NoQueueError.new("Jobs must be placed onto a queue.") if !queue
            raise ::Resque::NoClassError.new("Jobs must be given a class.") if klass.to_s.empty?
            ResqueSpec.queues[queue] << {:klass => klass.to_s, :args => args}
          end

          def destroy(queue, klass, *args)
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

    end

  end
end

Resque.extend ResqueSpec::Resque
Resque::Job.send :include, ResqueSpec::Resque::Job
