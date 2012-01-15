require 'rspec'

module InQueueHelper
  def self.extended(klass)
    klass.instance_eval do
      chain :in do |queue_name|
        self.queue_name = queue_name
      end
    end
  end

  private

  attr_accessor :queue_name

  def queue(actual)
    if @queue_name
      ResqueSpec.queue_by_name(@queue_name)
    else
      ResqueSpec.queue_for(actual)
    end
  end

end

RSpec::Matchers.define :have_queued do |*expected_args|
  extend InQueueHelper

  match do |actual|
    queue(actual).any? { |entry| entry[:class].to_s == actual.to_s && entry[:args] == expected_args }
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
  extend InQueueHelper

  match do |actual|
    queue(actual).size == size
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have #{size} entries queued, but got #{queue(actual).size} instead"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have #{size} entries queued, but got #{queue(actual).size} instead"
  end

  description do
    "have a queue size of #{size}"
  end
end

RSpec::Matchers.define :have_scheduled do |*expected_args|
  chain :at do |timestamp|
    @interval = nil
    @time = timestamp
    @time_info = "at #{@time}"
  end

  chain :in do |interval|
    @time = nil
    @interval = interval
    @time_info = "in #{@interval} seconds"
  end

  match do |actual|
    ResqueSpec.schedule_for(actual).any? do |entry|
      class_matches = entry[:class].to_s == actual.to_s
      args_match = entry[:args] == expected_args

      time_matches = if @time
        entry[:time] == @time
      elsif @interval
        entry[:time].to_i == entry[:stored_at].to_i + @interval
      else
        true
      end

      class_matches && args_match && time_matches
    end
  end

  failure_message_for_should do |actual|
    ["expected that #{actual} would have [#{expected_args.join(', ')}] scheduled", @time_info].join(' ')
  end

  failure_message_for_should_not do |actual|
    ["expected that #{actual} would not have [#{expected_args.join(', ')}] scheduled", @time_info].join(' ')
  end

  description do
    "have scheduled arguments"
  end
end

RSpec::Matchers.define :have_scheduled_at do |*expected_args|
  warn "DEPRECATION WARNING: have_scheduled_at(time, *args) is deprecated and will be removed in future. Please use have_scheduled(*args).at(time) instead."

  match do |actual|
    time = expected_args.first
    other_args = expected_args[1..-1]
    ResqueSpec.schedule_for(actual).any? { |entry| entry[:class].to_s == actual.to_s && entry[:time] == time && entry[:args] == other_args }
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have [#{expected_args.join(', ')}] scheduled"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would not have [#{expected_args.join(', ')}] scheduled"
  end

  description do
    "have scheduled at the given time the arguments"
  end
end

RSpec::Matchers.define :have_schedule_size_of do |size|
  match do |actual|
    ResqueSpec.schedule_for(actual).size == size
  end

  failure_message_for_should do |actual|
    "expected that #{actual} would have #{size} scheduled entries, but got #{ResqueSpec.schedule_for(actual).size} instead"
  end

  failure_message_for_should_not do |actual|
    "expected that #{actual} would have #{size} scheduled entries."
  end

  description do
    "have schedule size of #{size}"
  end
end
