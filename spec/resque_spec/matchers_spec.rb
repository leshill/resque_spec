require 'spec_helper'

describe "ResqueSpec Matchers" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "#have_queued" do
    context "queued with a class" do
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      subject { Person }

      it { should have_queued(first_name, last_name) }
      it { should_not have_queued(last_name, first_name) }
    end

    context "queued with a string" do
      before do
        Resque::Job.create(:people, "Person", first_name, last_name)
      end

      context "asserted with a class" do
        subject { Person }

        it { should have_queued(first_name, last_name) }
        it { should_not have_queued(last_name, first_name) }
      end

      context "asserted with a string" do
        subject { "Person" }

        it { should have_queued(first_name, last_name) }
        it { should_not have_queued(last_name, first_name) }
      end
    end

    context "#in" do

      before do
        Resque::Job.create(:people, "User", first_name, last_name)
      end

      subject { "User" }

      context "without #in(queue_name)" do
        it "should raise a Resque::NoQueueError" do
          lambda { "User".should have_queued(first_name, last_name) }.should raise_error(Resque::NoQueueError)
        end
      end

      context "with #in(queue_name)" do
        it { should have_queued(first_name, last_name).in(:people) }
        it { should_not have_queued(last_name, first_name).in(:people) }
      end
    end
  end

  describe "#have_queue_size_of" do
    context "queued with a class" do
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      subject { Person }

      it { should have_queue_size_of(1) }
    end

    describe "queued with a string" do
      before do
        Resque::Job.create(:people, "Person", first_name, last_name)
      end

      context "asserted with a class" do
        subject { Person }

        it { should have_queue_size_of(1) }
      end

      context "asserted with a string" do
        subject { "Person" }

        it { should have_queue_size_of(1) }
      end
    end
  end

  describe "#in" do
    before do
      Resque::Job.create(:people, "User", first_name, last_name)
    end

    subject { "User" }

    context "without #in(queue_name)" do
      it "should raise a Resque::NoQueueError" do
        lambda { "User".should have_queue_size_of(1) }.should raise_error(Resque::NoQueueError)
      end
    end

    context "with #in(queue_name)" do
      it { should have_queue_size_of(1).in(:people) }
    end
  end

  describe "#have_scheduled_at" do
    let(:scheduled_at) { Time.now + 5 * 60 }

    before do
      Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
    end

    it "returns true if the arguments are found in the queue" do
      Person.should have_scheduled_at(scheduled_at, first_name, last_name)
    end

    it "returns false if the arguments are not found in the queue" do
      Person.should_not have_scheduled_at(scheduled_at, last_name, first_name)
    end
  end

  describe "#have_scheduled" do
    before do
      Resque.enqueue_at(Time.now + 5 * 60, Person, first_name, last_name)
    end

    it "returns true if the arguments are found in the queue" do
      Person.should have_scheduled(first_name, last_name)
    end

    it "returns false if the arguments are not found in the queue" do
      Person.should_not have_scheduled(last_name, first_name)
    end
  end
end
