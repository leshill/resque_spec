require 'spec_helper'

describe "ResqueSchedulerSpec" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }
  let(:scheduled_at) { Time.now + 5 * 60 }

  describe "scheduled?" do
    it "returns true if the arguments were queued" do
      Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
      ResqueSpec.scheduled?(Person, scheduled_at, first_name, last_name).should be
    end

    it "returns false if the arguments were not queued" do
      ResqueSpec.scheduled?(Person, scheduled_at, first_name, last_name).should_not be
    end
  end

  describe "scheduled_anytime?" do
    it "returns true if the arguments were queued" do
      Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
      ResqueSpec.scheduled_anytime?(Person, first_name, last_name).should be
    end

    it "returns false if the arguments were not queued" do
      ResqueSpec.scheduled_anytime?(Person, first_name, last_name).should_not be
    end
  end

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

  describe "Resque" do
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

  context "Matchers" do
    before do
      Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
    end

    describe "#have_scheduled_at" do
      it "returns true if the arguments are found in the queue" do
        Person.should have_scheduled_at(scheduled_at, first_name, last_name)
      end

      it "returns false if the arguments are not found in the queue" do
        Person.should_not have_scheduled_at(scheduled_at, last_name, first_name)
      end
    end

    describe "#have_scheduled" do
      it "returns true if the arguments are found in the queue" do
        Person.should have_scheduled(first_name, last_name)
      end

      it "returns false if the arguments are not found in the queue" do
        Person.should_not have_scheduled(last_name, first_name)
      end
    end
  end
end
