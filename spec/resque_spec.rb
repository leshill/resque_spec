require 'spec_helper'

describe ResqueSpec do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "#dequeue" do
    let(:klass) { Object }
    let(:queue_name) { :queue_name }

    context "given just a class" do
      context "when the klass is queued" do
        it "removes the klass from the queue" do
          ResqueSpec.enqueue(queue_name, klass)
          ResqueSpec.dequeue(queue_name, klass)
          ResqueSpec.queue_by_name(queue_name).should_not include({ klass: klass, args: [] })
        end
      end

      context "when the klass is not queued" do
        it "does nothing" do
          ResqueSpec.enqueue(queue_name, klass, first_name, last_name)

          expect do
            ResqueSpec.dequeue(queue_name, klass)
          end.should_not change { ResqueSpec.queue_by_name(queue_name) }
        end
      end
    end

    context "given args" do
      before { ResqueSpec.enqueue(queue_name, klass, first_name, last_name) }

      context "when the klass and args are queued" do
        it "removes the klass and args from the queue" do
          ResqueSpec.dequeue(queue_name, klass, first_name, last_name)
          ResqueSpec.queue_by_name(queue_name).should_not include({ klass: klass.to_s, args: [first_name, last_name] })
        end
      end

      context "when the klass and args are not queued" do
        it "does nothing" do
          expect do
            ResqueSpec.dequeue(queue_name, klass, first_name)
          end.should_not change { ResqueSpec.queue_by_name(queue_name) }
        end
      end
    end
  end

  describe "#enqueue" do
    let(:klass) { Object }
    let(:queue_name) { :queue_name }

    it "queues the klass and args" do
      ResqueSpec.enqueue(queue_name, klass, first_name, last_name)
      ResqueSpec.queue_by_name(queue_name).should include({:klass => klass.to_s, :args => [first_name, last_name]})
    end

    it "queues the klass and an empty array" do
      ResqueSpec.enqueue(queue_name, klass)
      ResqueSpec.queue_by_name(queue_name).should include({:klass => klass.to_s, :args => []})
    end
  end

  describe "#queue_by_name" do

    it "has an empty array if nothing queued for a class" do
      ResqueSpec.queue_by_name(:my_queue).should == []
    end

    it "allows additions" do
      ResqueSpec.queue_by_name(:my_queue) << 'queued'
      ResqueSpec.queue_by_name(:my_queue).should_not be_empty
    end

  end

  describe "#queue_for" do
    it "raises if there is no queue defined for a class" do
      expect do
        ResqueSpec.queue_for(Address)
      end.should raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.queue_for(Person)
      end.should_not raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.queue_for(Account)
      end.should_not raise_error(::Resque::NoQueueError)
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

    it "returns the queue name for the name of the class" do
      ResqueSpec.queue_name("Person").should == :people
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
end
