require 'spec_helper'

describe "Resque Extensions" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "Resque" do
    before do
      Resque.enqueue(Person, "abc", "def")
      Resque.enqueue(Person, "xyz", "lmn")
      Resque.enqueue(Person, "xyz", "lmn")
    end

    describe "#enqueue" do

      context "queues" do
        before do
          Resque.enqueue(Person, first_name, last_name)
        end

        it "adds to the queue hash" do
          ResqueSpec.queue_for(Person).should_not be_empty
        end

        it "sets the klass on the queue" do
          ResqueSpec.queue_for(Person).last.should include(:class => Person.to_s)
        end

        it "sets the arguments on the queue" do
          ResqueSpec.queue_for(Person).last.should include(:args => [first_name, last_name])
        end
      end

      context "hooks" do
        it "calls the after_enqueue hook" do
          expect {
            Resque.enqueue(Person, first_name, last_name)
          }.to change(Person, :enqueues).by(1)
        end
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

  describe Resque::Job do
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
        ResqueSpec.queues[:people].last.should include(:class => Person.to_s)
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
end
