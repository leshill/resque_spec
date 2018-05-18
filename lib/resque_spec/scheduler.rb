require 'resque_spec'

module ResqueSpec
  module SchedulerExt
    def self.extended(klass)
      if klass.respond_to? :enqueue_at
        klass.instance_eval do
          alias :enqueue_at_without_resque_spec :enqueue_at
          alias :enqueue_at_with_queue_without_resque_spec :enqueue_at_with_queue
          alias :enqueue_in_without_resque_spec :enqueue_in
          alias :remove_delayed_without_resque_spec :remove_delayed
        end
      end
      klass.extend(ResqueSpec::SchedulerExtMethods)
    end
  end

  module SchedulerExtMethods
    def enqueue_at(time, klass, *args)
      return enqueue_at_without_resque_spec(time, klass, *args) if ResqueSpec.disable_ext && respond_to?(:enqueue_at_without_resque_spec)

      ResqueSpec.enqueue_at(time, klass, *args)
    end

    def enqueue_at_with_queue(queue, time, klass, *args)
      return enqueue_at_with_queue_without_resque_spec(queue, time, klass, *args) if ResqueSpec.disable_ext && respond_to?(:enqueue_at_with_queue_without_resque_spec)

      ResqueSpec.enqueue_at_with_queue(queue, time, klass, *args)
    end

    def enqueue_in(time, klass, *args)
      return enqueue_in_without_resque_spec(time, klass, *args) if ResqueSpec.disable_ext && respond_to?(:enqueue_in_without_resque_spec)

      ResqueSpec.enqueue_in(time, klass, *args)
    end

    def enqueue_in_with_queue(queue, time, klass, *args)
      return enqueue_in_with_queue_without_resque_spec(time, klass, *args) if ResqueSpec.disable_ext && respond_to?(:enqueue_in_with_queue_without_resque_spec)

      ResqueSpec.enqueue_in_with_queue(queue, time, klass, *args)
    end

    def remove_delayed(klass, *args)
      return remove_delayed_without_resque_spec(klass, *args) if ResqueSpec.disable_ext && respond_to?(:remove_delayed_without_resque_spec)

      ResqueSpec.remove_delayed(klass, *args)
    end
  end

  def enqueue_at(time, klass, *args)
    enqueue_at_with_queue(schedule_queue_name(klass), time, klass, *args)
  end

  def enqueue_at_with_queue(queue, time, klass, *args)
    is_time?(time)
    perform_or_store(queue, :class => klass.to_s, :time  => time, :stored_at => Time.now, :args => args)
  end

  def enqueue_in(time, klass, *args)
    enqueue_at(Time.now + time, klass, *args)
  end

  def enqueue_in_with_queue(queue, time, klass, *args)
    enqueue_at_with_queue(queue, Time.now + time, klass, *args)
  end

  def remove_delayed(klass, *args)
    sched_queue = queue_by_name(schedule_queue_name(klass))
    count_before_remove = sched_queue.length
    sched_queue.delete_if do |job|
      job[:class] == klass.to_s && job[:args] == args
    end
    # Return number of removed items to match Resque Scheduler behaviour
    count_before_remove - sched_queue.length
  end

  def schedule_for(klass)
    queue_by_name(schedule_queue_name(klass))
  end

  private

  def is_time?(time)
    time.to_i
  end

  def schedule_queue_name(klass)
    "#{queue_name(klass)}_scheduled"
  end
end

Resque.extend(ResqueSpec::SchedulerExt)
