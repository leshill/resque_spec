require 'rspec/core'
require 'rspec/expectations'
require 'rspec/mocks'

module ArgsHelper
  private

  def match_args(expected_args, args)
    arg_list_matcher = RSpec::Mocks::ArgumentListMatcher.new(*expected_args)
    arg_list_matcher.args_match?(*args)
  end
end

module InQueueHelper
  include ArgsHelper

  def self.included(klass)
    klass.class_eval do
      attr_accessor :queue_name
    end
  end

  def in(queue_name)
    self.queue_name = queue_name
    self
  end

  def queue(actual)
    if @queue_name
      ResqueSpec.queue_by_name(@queue_name)
    else
      ResqueSpec.queue_for(actual)
    end
  end
end

RSpec::Matchers.define :be_queued do |*expected_args|
  include InQueueHelper

  chain :times do |num_times_queued|
    @times = num_times_queued
    @times_info = @times == 1 ? ' once' : " #{@times} times"
  end

  chain :once do
    @times = 1
    @times_info = ' once'
  end

  match do |actual|
    matched = queue(actual).select do |entry|
      klass = entry.fetch(:class)
      args = entry.fetch(:args)
      klass.to_s == actual.to_s && match_args(expected_args, args)
    end

    if @times
      matched.size == @times
    else
      matched.size > 0
    end
  end

  failure_message do |actual|
    "expected that #{actual} would be queued with [#{expected_args.join(', ')}]#{@times_info}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not be queued with [#{expected_args.join(', ')}]#{@times_info}"
  end

  description do
    "be queued with arguments of [#{expected_args.join(', ')}]#{@times_info}"
  end

end

RSpec::Matchers.alias_matcher :have_queued, :be_queued

RSpec::Matchers.define :have_queue_size_of do |size|
  include InQueueHelper

  match do |actual|
    queue(actual).size == size
  end

  failure_message do |actual|
    "expected that #{actual} would have #{size} entries queued, but got #{queue(actual).size} instead"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not have #{size} entries queued, but got #{queue(actual).size} instead"
  end

  description do
    "have a queue size of #{size}"
  end
end

RSpec::Matchers.define :have_queue_size_of_at_least do |size|
  include InQueueHelper

  match do |actual|
    queue(actual).size >= size
  end

  failure_message do |actual|
    "expected that #{actual} would have at least #{size} entries queued, but got #{queue(actual).size} instead"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not have at least #{size} entries queued, but got #{queue(actual).size} instead"
  end

  description do
    "have a queue size of at least #{size}"
  end
end

module ScheduleQueueHelper
  include ArgsHelper

  def self.included(klass)
    klass.class_eval do
      attr_accessor :queue_name
    end
  end

  def queue(queue_name)
    self.queue_name = queue_name
    self
  end

  def schedule_queue_for(actual)
    if @queue_name
      ResqueSpec.queue_by_name(@queue_name)
    else
      ResqueSpec.schedule_for(actual)
    end
  end

  def scheduled_jobs_for(name)
    ResqueSpec.queue_by_name(name)
  end
end

RSpec::Matchers.define :have_set_schedule do |*expected_args|
  include ScheduleQueueHelper

  chain :with_cron do |cron_rule|
    @cron = cron_rule
    @cron_rule_info = "with cron #@cron"
  end

  match do |actual|
    scheduled_jobs_for(actual).any? do |entry|
      args_match = match_args(expected_args, entry[:args])

      cron_matches = if @cron
                       entry[:cron] == @cron
                     else
                       true
                     end

      args_match && cron_matches
    end
  end

  match_when_negated do |actual|
    return true if scheduled_jobs_for(actual).empty?

    scheduled_jobs_for(actual).any? do |entry|
      args_match = match_args(expected_args, entry[:args])

      cron_matches = if @cron
                       entry[:cron] == @cron
                     else
                       true
                     end

      !(args_match && cron_matches)
    end
  end

  failure_message do |actual|
    ["expected that schedule queue #{actual} would have [#{expected_args.join(', ')}] scheduled", @cron_rule_info].join(' ')
  end

  failure_message_when_negated do |actual|
    ["expected that schedule queue #{actual} would not have [#{expected_args.join(', ')}] scheduled", @cron_rule_info].join(' ')
  end

  description do
    "have set schedule"
  end
end

RSpec::Matchers.define :have_scheduled do |*expected_args|
  include ScheduleQueueHelper

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
    schedule_queue_for(actual).any? do |entry|
      class_matches = entry[:class].to_s == actual.to_s
      args_match = match_args(expected_args, entry[:args])

      time_matches = if @time
        entry[:time].to_i == @time.to_i
      elsif @interval
        entry[:time].to_i == (entry[:stored_at] + @interval).to_i
      else
        true
      end

      class_matches && args_match && time_matches
    end
  end

  failure_message do |actual|
    ["expected that #{actual} would have [#{expected_args.join(', ')}] scheduled", @time_info].join(' ')
  end

  failure_message_when_negated do |actual|
    ["expected that #{actual} would not have [#{expected_args.join(', ')}] scheduled", @time_info].join(' ')
  end

  description do
    "have scheduled arguments"
  end
end

RSpec::Matchers.define :have_scheduled_at do |*expected_args|
  include ScheduleQueueHelper
  warn "DEPRECATION WARNING: have_scheduled_at(time, *args) is deprecated and will be removed in future. Please use have_scheduled(*args).at(time) instead."

  match do |actual|
    time = expected_args.first
    other_args = expected_args[1..-1]
    schedule_queue_for(actual).any? { |entry| entry[:class].to_s == actual.to_s && entry[:time] == time && match_args(other_args, entry[:args]) }
  end

  failure_message do |actual|
    "expected that #{actual} would have [#{expected_args.join(', ')}] scheduled"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not have [#{expected_args.join(', ')}] scheduled"
  end

  description do
    "have scheduled at the given time the arguments"
  end
end

RSpec::Matchers.define :have_schedule_size_of do |size|
  include ScheduleQueueHelper

  match do |actual|
    schedule_queue_for(actual).size == size
  end

  failure_message do |actual|
    "expected that #{actual} would have #{size} scheduled entries, but got #{schedule_queue_for(actual).size} instead"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would have #{size} scheduled entries."
  end

  description do
    "have schedule size of #{size}"
  end
end

RSpec::Matchers.define :have_schedule_size_of_at_least do |size|
  include ScheduleQueueHelper

  match do |actual|
    schedule_queue_for(actual).size >= size
  end

  failure_message do |actual|
    "expected that #{actual} would have at least #{size} scheduled entries, but got #{schedule_queue_for(actual).size} instead"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would have at least #{size} scheduled entries."
  end

  description do
    "have schedule size of #{size}"
  end
end
