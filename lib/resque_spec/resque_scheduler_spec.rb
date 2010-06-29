require 'resque_spec'

module ResqueSpec

  def scheduled?(klass, time, *args)
    schedule_for(klass).any? {|entry| entry[:klass] == klass && entry[:time] == time && entry[:args] == args}
  end

  def scheduled_anytime?(klass, *args)
    schedule_for(klass).any? {|entry| entry[:klass] == klass && entry[:args] == args}
  end

  def schedule_for(klass)
    name = queue_name(klass).to_s << "_scheduled"
    queues[name]
  end

  module ResqueScheduler
    def enqueue_at(time, klass, *args)
      ResqueSpec.schedule_for(klass) << {:klass => klass, :time  => time, :args => args}
    end
  end
end

Resque.extend(ResqueSpec::ResqueScheduler)

RSpec::Matchers.define :have_scheduled do |*expected_args|
  match do |actual|
    ResqueSpec.scheduled_anytime?(actual, *expected_args)
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have [#{expected_args.join(', ')}] queued"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have [#{expected_args.join(', ')}] queued"
  end

  description do
    "have scheduled arguments"
  end
end

RSpec::Matchers.define :have_scheduled_at do |*expected_args|
  match do |actual|
    ResqueSpec.scheduled?(actual, *expected_args)
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have [#{expected_args.join(', ')}] queued"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have [#{expected_args.join(', ')}] queued"
  end

  description do
    "have scheduled at the given time the arguments"
  end
end

