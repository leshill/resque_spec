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
        it "removes the klass items from the queue" do
          ResqueSpec.enqueue(queue_name, klass, first_name, last_name)
          ResqueSpec.dequeue(queue_name, klass)
          ResqueSpec.queue_by_name(queue_name).should_not include({ class: klass.to_s, args: [first_name, last_name] })
        end
      end

      context "when the klass is not queued" do
        it "does nothing" do
          ResqueSpec.enqueue(queue_name, String, first_name, last_name)

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
          ResqueSpec.queue_by_name(queue_name).should_not include({ class: klass.to_s, args: [first_name, last_name] })
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
      ResqueSpec.queue_by_name(queue_name).should include({:class => klass.to_s, :args => [first_name, last_name]})
    end

    it "queues the klass and an empty array" do
      ResqueSpec.enqueue(queue_name, klass)
      ResqueSpec.queue_by_name(queue_name).should include({:class => klass.to_s, :args => []})
    end
  end

  describe "#inline" do
    context "when not set" do
      before { ResqueSpec.inline = false }

      it "does not perform the queued action" do
        expect {
          ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 1)
        }.should_not change(NameFromClassMethod, :invocations)
      end

      it "does not change the behavior of enqueue" do
        ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 1)
        ResqueSpec.queue_by_name(:queue_name).should include({ class: NameFromClassMethod.to_s, args: [1] })
      end
    end

    context "when set" do
      before { ResqueSpec.inline = true }

      it "performs the queued action" do
        expect {
          ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 1)
        }.should change(NameFromClassMethod, :invocations).by(1)
      end

      it "does not enqueue" do
        ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 1)
        ResqueSpec.queue_by_name(:queue_name).should be_empty
      end
    end
  end

  describe "#perform_all" do
    before do
      ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 1)
      ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 2)
      ResqueSpec.enqueue(:queue_name, NameFromClassMethod, 3)
    end

    it "performs the enqueued job" do
      expect {
        ResqueSpec.perform_all(:queue_name)
      }.should change(NameFromClassMethod, :invocations).by(3)
    end

    it "removes all items from the queue" do
      expect {
        ResqueSpec.perform_all(:queue_name)
      }.should change { ResqueSpec.queue_by_name(:queue_name).empty? }.from(false).to(true)
    end
  end

  describe "#perform_next" do
    before { 3.times {|i| ResqueSpec.enqueue(:queue_name, NameFromClassMethod, i) }}

    it "performs the enqueued job" do
      expect {
        ResqueSpec.perform_next(:queue_name)
      }.should change(NameFromClassMethod, :invocations).by(1)
    end

    it "removes an item from the queue" do
      expect {
        ResqueSpec.perform_next(:queue_name)
      }.should change { ResqueSpec.queue_by_name(:queue_name).size }.by(-1)
    end
  end

  describe "#queue_by_name" do

    it "has an empty array if nothing queued for a class" do
      ResqueSpec.queue_by_name(:my_queue).should == []
    end

    it "converts symbol names to strings" do
      ResqueSpec.queue_by_name(:my_queue) << 'queued'
      ResqueSpec.queues['my_queue'].should_not be_empty
    end

    it "allows additions" do
      ResqueSpec.queue_by_name(:my_queue) << 'queued'
      ResqueSpec.queue_by_name(:my_queue).should_not be_empty
    end

  end

  describe "#queue_for" do
    it "raises if there is no queue defined for a class" do
      expect do
        ResqueSpec.queue_for(String)
      end.should raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class instance variable" do
      expect do
        ResqueSpec.queue_for(NameFromInstanceVariable)
      end.should_not raise_error(::Resque::NoQueueError)
    end

    it "recognizes a queue defined as a class method" do
      expect do
        ResqueSpec.queue_for(NameFromClassMethod)
      end.should_not raise_error(::Resque::NoQueueError)
    end

  end

  describe "#queue_name" do
    it "raises if there is no queue defined for a class" do
      expect do
        ResqueSpec.queue_name(String)
      end.should raise_error(::Resque::NoQueueError)
    end

    it "returns the queue name if there is a queue defined as an instance var" do
      ResqueSpec.queue_name(NameFromInstanceVariable).should == 'name_from_instance_variable'
    end

    it "returns the queue name for the name of the class" do
      ResqueSpec.queue_name("NameFromClassMethod").should == NameFromClassMethod.queue
    end

    it "returns the queue name if there is a queue defined via self.queue" do
      ResqueSpec.queue_name(NameFromClassMethod).should == NameFromClassMethod.queue
    end
  end

  describe "#pop" do
    subject { ResqueSpec.pop(:queue_name) }

    context "when the queue is empty" do
      it { should be_nil }
    end

    context "when the queue has at least one job" do
      before { 3.times {|i| ResqueSpec.enqueue(:queue_name, NameFromClassMethod, i) }}

      it { should be_kind_of(Resque::Job) }

      it "removes the first item from the queue" do
        subject
        ResqueSpec.queue_by_name(:queue_name).map {|h| h[:args] }.flatten.should_not include(0)
      end
    end
  end

  describe "#reset!" do
    it "clears the queues" do
      ResqueSpec.queue_for(NameFromClassMethod) << 'queued'
      ResqueSpec.reset!
      ResqueSpec.queues.should be_empty
    end

    it "resets the inline status" do
      ResqueSpec.inline = true
      ResqueSpec.reset!
      ResqueSpec.inline.should be_false
    end
  end

end
