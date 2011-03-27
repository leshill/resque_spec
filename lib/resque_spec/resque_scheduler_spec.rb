require 'resque_spec'

module ResqueSpec

  def schedule_for(klass)
    name = "#{queue_name(klass)}_scheduled"
    queues[name]
  end

  module ResqueScheduler
    def enqueue_at(time, klass, *args)
      ResqueSpec.schedule_for(klass) << {:klass => klass.to_s, :time  => time, :args => args}
    end
  end

end

Resque.extend(ResqueSpec::ResqueScheduler)
