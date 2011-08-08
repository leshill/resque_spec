require 'resque_spec'

module ResqueSpec
  module SchedulerExt
    def enqueue_at(time, klass, *args)
      ResqueSpec.enqueue_at(time, klass, *args)
    end

    def enqueue_in(time, klass, *args)
      ResqueSpec.enqueue_in(time, klass, *args)
    end

    def remove_delayed(klass, *args)
      ResqueSpec.remove_delayed(klass, *args)
    end
  end

  def enqueue_at(time, klass, *args)
    perform_or_store(schedule_queue_name(klass), :class => klass.to_s, :time  => time, :args => args)
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
    queues[schedule_queue_name(klass)]
  end

  private

  def schedule_queue_name(klass)
    "#{queue_name(klass)}_scheduled"
  end
end

Resque.extend(ResqueSpec::SchedulerExt)
