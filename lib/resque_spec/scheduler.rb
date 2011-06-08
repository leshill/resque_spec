require 'resque_spec'

module ResqueSpec
  module SchedulerExt
    def enqueue_at(time, klass, *args)
      ResqueSpec.enqueue_at(time, klass, *args)
    end

    def enqueue_in(time, klass, *args)
      ResqueSpec.enqueue_in(time, klass, *args)
    end
  end

  def enqueue_at(time, klass, *args)
    store(schedule_queue_name(klass), klass, { :class => klass.to_s, :time  => time, :args => args })
  end

  def enqueue_in(time, klass, *args)
    enqueue_at(Time.now + time, klass, *args)
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
