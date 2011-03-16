require 'resque_spec'

module ResqueSpec

  def scheduled?(klass, time, *args)
    schedule_for(klass).any? {|entry| entry[:klass].to_s == klass.to_s && entry[:time] == time && entry[:args] == args}
  end

  def scheduled_anytime?(klass, *args)
    schedule_for(klass).any? {|entry| entry[:klass].to_s == klass.to_s && entry[:args] == args}
  end

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

