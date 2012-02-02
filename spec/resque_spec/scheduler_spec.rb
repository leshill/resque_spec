require 'spec_helper'

describe ResqueSpec do

  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }
  let(:scheduled_at) { Time.now + 5 * 60 }
  let(:scheduled_in) { 5 * 60 }

  describe "#schedule_for" do
    it "raises if there is no schedule queue defined for a class" do
      expect do
        ResqueSpec.schedule_for(String)
      end.should raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.schedule_for(NameFromInstanceVariable)
      end.should_not raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.schedule_for(NameFromClassMethod)
      end.should_not raise_error(::Resque::NoQueueError)
    end

    it "has an empty array if nothing queued for a class" do
      ResqueSpec.schedule_for(NameFromClassMethod).should == []
    end

    it "allows additions" do
      ResqueSpec.schedule_for(NameFromClassMethod) << 'queued'
      ResqueSpec.schedule_for(NameFromClassMethod).should_not be_empty
    end

    it "does not mutate the @queue if it is a string" do
      ResqueSpec.schedule_for(NameFromInstanceVariable)
      NameFromInstanceVariable.instance_variable_get(:@queue).should == 'name_from_instance_variable'
    end
  end

  describe Resque do
    describe "#enqueue_at" do

      before do
        Timecop.travel(Time.at(0)) do
          Resque.enqueue_at(scheduled_at, NameFromClassMethod, 1)
        end
      end

      it "adds to the scheduled queue hash" do
        ResqueSpec.schedule_for(NameFromClassMethod).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.schedule_for(NameFromClassMethod).first.should include(:class => NameFromClassMethod.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.schedule_for(NameFromClassMethod).first.should include(:args => [1])
      end

      it "sets the time on the scheduled queue" do
        ResqueSpec.schedule_for(NameFromClassMethod).first.should include(:time => scheduled_at)
      end

      it "sets the stored_at on the scheduled queue" do
        # Comparing this explicitly will fail (Timecop bug?)
        ResqueSpec.schedule_for(NameFromClassMethod).first[:stored_at].to_i.should == Time.at(0).to_i
      end

    end

    describe "#enqueue_at_with_queue" do

      before do
        Timecop.travel(Time.at(0)) do
          Resque.enqueue_at_with_queue(:specified, scheduled_at, NameFromClassMethod, 1)
        end
      end

      it "adds to the queue hash" do
        ResqueSpec.queue_by_name(:specified).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_by_name(:specified).first.should include(:class => NameFromClassMethod.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_by_name(:specified).first.should include(:args => [1])
      end

      it "sets the time on the scheduled queue" do
        ResqueSpec.queue_by_name(:specified).first.should include(:time => scheduled_at)
      end

      it "sets the stored_at on the scheduled queue" do
        # Comparing this explicitly will fail (Timecop bug?)
        ResqueSpec.queue_by_name(:specified).first[:stored_at].to_i.should == Time.at(0).to_i
      end

    end

    describe "#enqueue_in" do
      before do
        Timecop.freeze(Time.now)
        Resque.enqueue_in(scheduled_in, NameFromClassMethod, 1)
      end

      after do
        Timecop.return
      end

      it "adds to the scheduled queue hash" do
        ResqueSpec.schedule_for(NameFromClassMethod).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.schedule_for(NameFromClassMethod).first.should include(:class => NameFromClassMethod.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.schedule_for(NameFromClassMethod).first.should include(:time => Time.now + scheduled_in)
      end
    end

    describe "#enqueue_in_with_queue" do
      before do
        Timecop.freeze(Time.now)
        Resque.enqueue_in_with_queue(:specified, scheduled_in, NameFromClassMethod, 1)
      end

      after do
        Timecop.return
      end

      it "adds to the queue hash" do
        ResqueSpec.queue_by_name(:specified).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_by_name(:specified).first.should include(:class => NameFromClassMethod.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_by_name(:specified).first.should include(:time => Time.now + scheduled_in)
      end
    end

    describe "#remove_delayed" do
      describe "with #enqueue_at" do
        before do
          Resque.enqueue_at(scheduled_at, NameFromClassMethod, 1)
        end

        it "should remove a scheduled item from the queue" do
          Resque.remove_delayed(NameFromClassMethod, 1)
          ResqueSpec.schedule_for(NameFromClassMethod).should be_empty
        end
      end

      describe "with #enqueue_in" do
        before do
          Timecop.freeze(Time.now)
          Resque.enqueue_in(scheduled_in, NameFromClassMethod, 1)
        end

        after do
          Timecop.return
        end

        it "should remove a scheduled item from the queue" do
          Resque.remove_delayed(NameFromClassMethod, 1)
          ResqueSpec.schedule_for(NameFromClassMethod).should be_empty
        end
      end

    end
  end
end
