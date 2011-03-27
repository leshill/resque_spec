require 'spec_helper'

describe "ResqueSpec" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

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

  describe "Resque" do
    before do
      Resque.enqueue(Person, "abc", "def")
      Resque.enqueue(Person, "xyz", "lmn")
      Resque.enqueue(Person, "xyz", "lmn")
    end

    describe "#enqueue" do

      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      it "adds to the queue hash" do
        ResqueSpec.queue_for(Person).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_for(Person).last.should include(:klass => Person.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_for(Person).last.should include(:args => [first_name, last_name])
      end

    end

    describe "#dequeue" do
      describe "without arguments" do
        it "should remove all items from queue with the given class" do
          ResqueSpec.queue_for(Person).count.should == 3
          expect do
            Resque.dequeue(Person).should == 3
          end.should change(ResqueSpec.queue_for(Person), :count).by(-3)
          ResqueSpec.queue_for(Person).count.should == 0
        end
      end

      describe "with arguments" do
        it "should remove items from queue with the given class and arguments" do
          ResqueSpec.queue_for(Person).count.should == 3
          expect do
            Resque.dequeue(Person, "xyz", "lmn").should == 2
          end.should change(ResqueSpec.queue_for(Person), :size).by(-2)
          ResqueSpec.queue_for(Person).count.should == 1
        end
      end
    end
  end

  describe "Resque::Job" do
    before do
      Resque.enqueue(Person, "abc", "def")
      Resque.enqueue(Person, "xyz", "lmn")
      Resque.enqueue(Person, "xyz", "lmn")
    end

    describe "#create" do
      before do
        ::Resque::Job.create(:people, Person, first_name, last_name)
      end

      it "adds to the queue hash" do
        ResqueSpec.queues[:people].should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queues[:people].last.should include(:klass => Person.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queues[:people].last.should include(:args => [first_name, last_name])
      end
    end

    describe "#destroy" do
      describe "without arguments" do
        it "should remove all items from queue with the given class" do
          ResqueSpec.queue_for(Person).count.should == 3
          expect do
            Resque::Job.destroy(:people, Person).should == 3
          end.should change(ResqueSpec.queue_for(Person), :count).by(-3)
          ResqueSpec.queue_for(Person).count.should == 0
        end
      end

      describe "with arguments" do
        it "should remove items from queue with the given class and arguments" do
          ResqueSpec.queue_for(Person).count.should == 3
          expect do
            Resque::Job.destroy(:people, Person, "xyz", "lmn").should == 2
          end.should change(ResqueSpec.queue_for(Person), :size).by(-2)
          ResqueSpec.queue_for(Person).count.should == 1
        end
      end
    end
  end

  context "Matchers" do
    describe "given a class" do
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      subject { Person }

      describe "#have_queued" do
        it { should have_queued(first_name, last_name) }
        it { should_not have_queued(last_name, first_name) }
      end

      describe "#have_queue_size_of" do
        it { should have_queue_size_of(1) }
      end
    end

    describe "given a class name" do
      before do
        Resque::Job.create(:people, "Person", first_name, last_name)
      end

      subject { Person }

      describe "#have_queued" do
        it { should have_queued(first_name, last_name) }
        it { should_not have_queued(last_name, first_name) }
      end

      describe "#have_queue_size_of" do
        it { should have_queue_size_of(1) }
      end

      subject { "Person" }

      describe "#have_queued" do
        it { should have_queued(first_name, last_name) }
        it { should_not have_queued(last_name, first_name) }
      end

      describe "#have_queue_size_of" do
        it { should have_queue_size_of(1) }
      end
    end

    describe "given a name for a non-existent class (e.g. the class is on a separate application processing the Resque jobs)" do
      before do
        Resque::Job.create(:people, "User", first_name, last_name)
      end

      subject { "User" }

      describe "#have_queued" do
        describe "without #in(queue_name)" do
          it "should raise a Resque::NoQueueError" do
            lambda { "User".should have_queued(first_name, last_name) }.should raise_error(Resque::NoQueueError)
          end
        end

        describe "with #in(queue_name)" do
          it { should have_queued(first_name, last_name).in(:people) }
          it { should_not have_queued(last_name, first_name).in(:people) }
        end
      end

      describe "#have_queue_size_of" do
        describe "without #in(queue_name)" do
          it "should raise a Resque::NoQueueError" do
            lambda { "User".should have_queue_size_of(1) }.should raise_error(Resque::NoQueueError)
          end
        end

        describe "with #in(queue_name)" do
          it { should have_queue_size_of(1).in(:people) }
        end

      end
    end
  end
end
