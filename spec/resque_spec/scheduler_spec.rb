require 'spec_helper'

describe ResqueSpec do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }
  let(:scheduled_at) { Time.now + 5 * 60 }

  describe "#schedule_for" do
    it "raises if there is no schedule queue defined for a class" do
      expect do
        ResqueSpec.schedule_for(Address)
      end.should raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.schedule_for(Person)
      end.should_not raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.schedule_for(Account)
      end.should_not raise_error(::Resque::NoQueueError)
    end

    it "has an empty array if nothing queued for a class" do
      ResqueSpec.schedule_for(Person).should == []
    end

    it "allows additions" do
      ResqueSpec.schedule_for(Person) << 'queued'
      ResqueSpec.schedule_for(Person).should_not be_empty
    end

    it "does not mutate the Book's @queue if it is a string" do
      ResqueSpec.schedule_for(Book)
      Book.instance_variable_get(:@queue).should == 'book'
    end
  end

  describe Resque do
    describe "#enqueue_at" do

      before do
        Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
      end

      it "adds to the scheduled queue hash" do
        ResqueSpec.schedule_for(Person).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.schedule_for(Person).first.should include(:klass => Person.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.schedule_for(Person).first.should include(:args => [first_name, last_name])
      end

      it "sets the time on the scheduled queue" do
        ResqueSpec.schedule_for(Person).first.should include(:time => scheduled_at)
      end

    end
  end
end
