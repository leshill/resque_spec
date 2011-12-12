require 'spec_helper'

describe "ResqueSpec" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "#queue_for" do
    it "raises if there is no queue defined for a class" do
      expect do
        ResqueSpec.queue_for(Address)
      end.should raise_exception(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.queue_for(Person)
      end.should_not raise_exception(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.queue_for(Account)
      end.should_not raise_exception(::Resque::NoQueueError)
    end

    it "has an empty array if nothing queued for a class" do
      ResqueSpec.queue_for(Person).should == []
    end

    it "allows additions" do
      ResqueSpec.queue_for(Person) << 'queued'
      ResqueSpec.queue_for(Person).should_not be_empty
    end
  end

  describe "#queue_name" do
    it "raises if there is no queue defined for a class" do
      expect do
        ResqueSpec.queue_name(Address)
      end.should raise_error(::Resque::NoQueueError)
    end

    it "returns the queue name if there is a queue defined as an instance var" do
      ResqueSpec.queue_name(Person).should == :people
    end

    it "returns the queue name if there is a queue defined via self.queue" do
      ResqueSpec.queue_name(Account).should == :people
    end
  end

  describe "#reset!" do
    it "clears the queues" do
      ResqueSpec.queue_for(Person) << 'queued'
      ResqueSpec.reset!
      ResqueSpec.queues.should be_empty
    end
  end

  describe "#in_queue?" do
    it "returns true if the arguments were queued" do
      Resque.enqueue(Person, first_name, last_name)
      ResqueSpec.in_queue?(Person, first_name, last_name).should be
    end

    it "returns false if the arguments were not queued" do
      ResqueSpec.in_queue?(Person, first_name, last_name).should_not be
    end
  end

  describe "#perform_all" do
    before do
      Resque.enqueue(NameFromClassMethod, 1)
      Resque.enqueue(NameFromClassMethod, 2)
      Resque.enqueue(NameFromClassMethod, 3)
    end

    it "performs the enqueued job" do
      ResqueSpec.queue_for(NameFromClassMethod).should_not be_empty

      puts NameFromClassMethod.invocations

      expect {
        ResqueSpec.perform_all(:name_from_class_method)
      }.should change(NameFromClassMethod, :invocations).by(3)
    end

    it "removes all items from the queue" do
      ResqueSpec.queue_for(NameFromClassMethod).should_not be_empty

      expect {
        ResqueSpec.perform_all(:name_from_class_method)
      }.should change { ResqueSpec.queue_by_name(:name_from_class_method).empty? }.from(false).to(true)
    end
  end

  describe "Resque" do
    describe "#enqueue" do

      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      it "adds to the queue hash" do
        ResqueSpec.queue_for(Person).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_for(Person).first.should include(:klass => Person)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_for(Person).first.should include(:args => [first_name, last_name])
      end

    end
  end

  context "Matchers" do
    before do
      Resque.enqueue(Person, first_name, last_name)
    end

    describe "#have_queued" do
      it "returns true if the arguments are found in the queue" do
        Person.should have_queued(first_name, last_name)
      end

      it "returns false if the arguments are not found in the queue" do
        Person.should_not have_queued(last_name, first_name)
      end
    end
  end
end
