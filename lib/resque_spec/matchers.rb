require 'rspec'

RSpec::Matchers.define :have_queued do |*expected_args|
  match do |actual|
    ResqueSpec.in_queue?(actual, *expected_args, :queue_name => @queue_name)
  end
  
  chain :in do |queue_name|
    @queue_name = queue_name
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have [#{expected_args.join(', ')}] queued"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have [#{expected_args.join(', ')}] queued"
  end

  description do
    "have queued arguments of [#{expected_args.join(', ')}]"
  end
end

RSpec::Matchers.define :have_queue_size_of do |size|
  match do |actual|
    (@queue ||= ResqueSpec.queue_for(actual)).size == size
  end
  
  chain :in do |queue_name|
    @queue = ResqueSpec.queues[queue_name]
  end  

  failure_message_for_should do |actual|
    "expected that #{actual} would have #{size} entries queued, but got #{@queue.size} instead"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have #{size} entries queued, but got #{@queue..size} instead"
  end

  description do
    "have a queue size of #{size}"
  end
end

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