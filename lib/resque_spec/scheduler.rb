require 'resque_spec'

module ResqueSpec
  module SchedulerExt
    def self.extended(klass)
      if klass.respond_to? :enqueue_at
        klass.instance_eval do
          alias :enqueue_at_without_resque_spec :enqueue_at
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

    def enqueue_in(time, klass, *args)
      return enqueue_in_without_resque_spec(time, klass, *args) if ResqueSpec.disable_ext && respond_to?(:enqueue_in_without_resque_spec)

      ResqueSpec.enqueue_in(time, klass, *args)
    end

    def remove_delayed(klass, *args)
      return remove_delayed_without_resque_spec(klass, *args) if ResqueSpec.disable_ext && respond_to?(:remove_delayed_without_resque_spec)

      ResqueSpec.remove_delayed(klass, *args)
    end
  end

  def enqueue_at(time, klass, *args)
    perform_or_store(schedule_queue_name(klass), :class => klass.to_s, :time  => time, :stored_at => Time.now, :args => args)
  end

  def enqueue_in(time, klass, *args)
    enqueue_at(Time.now + time, klass, *args)
  end

  def remove_delayed(klass, *args)
    queue_by_name(schedule_queue_name(klass)).delete_if do |job|
      job[:class] == klass.to_s && job[:args] == args
    end
  end

  def schedule_for(klass)
    queue_by_name(schedule_queue_name(klass))
  end

  private

  def schedule_queue_name(klass)
    "#{queue_name(klass)}_scheduled"
  end
end

Resque.extend(ResqueSpec::SchedulerExt)
