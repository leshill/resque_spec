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
      end.to raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.schedule_for(NameFromInstanceVariable)
      end.not_to raise_error()
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.schedule_for(NameFromClassMethod)
      end.not_to raise_error()
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
      context "when given a Time" do
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

      context "when given a Date" do
        it "raises an exception like resque-scheduler" do
          expect do
            Resque.enqueue_at(Date.new, NameFromClassMethod, 1)
          end.to raise_error(NoMethodError)
        end
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

    describe "#enqueue_at_with_queue" do
      before do
        Timecop.travel(Time.at(0)) do
          Resque.enqueue_at_with_queue(:test_queue, scheduled_at, NoQueueClass, 1)
        end
      end

      it "adds to the scheduled queue hash" do
        ResqueSpec.queue_by_name(:test_queue).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_by_name(:test_queue).first.should include(:class => NoQueueClass.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_by_name(:test_queue).first.should include(:time => scheduled_at)
      end

      it "uses the correct queue" do
        ResqueSpec.queue_by_name(:test_queue).should_not be_empty
      end
    end

    describe "#enqueue_in_with_queue" do
      before do
        Timecop.freeze(Time.now)
        Resque.enqueue_in_with_queue(:test_queue, scheduled_in, NoQueueClass, 1)
      end

      after do
        Timecop.return
      end

      it "adds to the scheduled queue hash" do
        ResqueSpec.queue_by_name(:test_queue).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_by_name(:test_queue).first.should include(:class => NoQueueClass.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_by_name(:test_queue).first.should include(:time => Time.now + scheduled_in)
      end

      it "uses the correct queue" do
        ResqueSpec.queue_by_name(:test_queue).should_not be_empty
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

        it "should return the number of removed items" do
          Resque.remove_delayed(NameFromClassMethod, 1).should == 1
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

        it "should return the number of removed items" do
          Resque.remove_delayed(NameFromClassMethod, 1).should == 1
        end
      end

    end
  end

  context "when disable_ext is set to get the default behavior of Resque" do
    around { |example| without_resque_spec { example.run } }

    describe "Resque" do
      describe ".enqueue_at" do
        it "calls the original Resque.enqueue_at method" do
          timestamp = Time.now
          Resque.should_receive(:enqueue_at_without_resque_spec).with(NameFromClassMethod, 1)
          Resque.enqueue_at(NameFromClassMethod, 1)
        end
      end

      describe ".enqueue_at_with_queue" do
        it "calls the original Resque.enqueue_at_with_queue method" do
          timestamp = Time.now
          Resque.should_receive(:enqueue_at_with_queue_without_resque_spec).with("test", NameFromClassMethod, 1)
          Resque.enqueue_at_with_queue("test", NameFromClassMethod, 1)
        end
      end

      describe ".enqueue_in" do
        it "calls the original Resque.enqueue_in method" do
          wait_time = 500
          Resque.should_receive(:enqueue_in_without_resque_spec).with(wait_time, NameFromClassMethod, 1)
          Resque.enqueue_in(wait_time, NameFromClassMethod, 1)
        end
      end

      describe ".remove_delayed" do
        it "calls the original Resque.remove_delayed method" do
          Resque.should_receive(:remove_delayed_without_resque_spec).with(NameFromClassMethod, 1)
          Resque.remove_delayed(NameFromClassMethod, 1)
        end
      end
    end
  end
end
