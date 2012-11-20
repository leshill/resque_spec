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

      context "with anything matcher" do
        subject { "Person" }

        it { should have_queued(anything, anything) }
        it { should have_queued(anything, last_name) }
        it { should have_queued(first_name, anything) }
        it { should_not have_queued(anything) }
        it { should_not have_queued(anything, anything, anything) }
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

      context "without #in(:places) after #in(:people)" do
        before { should have_queued(first_name, last_name).in(:people) }
        before { Resque.enqueue(Place) }

        specify { Place.should have_queued }
      end
    end

    context "#times" do

      subject { Person }

      context "job queued once" do
        before do
          Resque.enqueue(Person, first_name, last_name)
        end

        it { should_not have_queued(first_name, last_name).times(0) }
        it { should have_queued(first_name, last_name).times(1) }
        it { should_not have_queued(first_name, last_name).times(2) }
      end

      context "no job queued" do
        it { should have_queued(first_name, last_name).times(0) }
        it { should_not have_queued(first_name, last_name).times(1) }
      end
    end

    context "#once" do

      subject { Person }

      context "job queued once" do
        before do
          Resque.enqueue(Person, first_name, last_name)
        end

        it { should have_queued(first_name, last_name).once }
      end

      context "no job queued" do
        it { should_not have_queued(first_name, last_name).once }
      end
    end
  end

  describe "#have_queue_size_of" do
    context "when nothing is queued" do
      subject { Person }

      it "raises the approrpiate exception" do
        expect do
          should have_queue_size_of(1)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

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

  describe "#have_queue_size_of_at_least" do
    context "when nothing is queued" do
      subject { Person }

      it "raises the approrpiate exception" do
        expect do
          should have_queue_size_of_at_least(1)
        end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
      end
    end

    context "queued with a class" do
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      subject { Person }

      it { should have_queue_size_of_at_least(1) }
    end

    describe "queued with a string" do
      before do
        2.times { Resque::Job.create(:people, "Person", first_name, last_name) }
      end

      context "asserted with a class" do
        subject { Person }

        it { should have_queue_size_of_at_least(2) }
      end

      context "asserted with a string" do
        subject { "Person" }

        it { should have_queue_size_of_at_least(1) }
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

    context "with #in('queue_name')" do
      it { should have_queue_size_of(1).in('people') }
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

    it "returns true if the arguments are found in the queue with anything matcher" do
      Person.should have_scheduled_at(scheduled_at, anything, anything)
      Person.should have_scheduled_at(scheduled_at, anything, last_name)
      Person.should have_scheduled_at(scheduled_at, first_name, anything)
    end

    it "returns false if the arguments are not found in the queue" do
      Person.should_not have_scheduled_at(scheduled_at, last_name, first_name)
    end
  end

  describe "#have_scheduled" do
    let(:scheduled_at) { Time.now + 5 * 60 }

    before do
      Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
    end

    it "returns true if the arguments are found in the queue" do
      Person.should have_scheduled(first_name, last_name)
    end

    it "returns true if arguments are found in the queue with anything matcher" do
      Person.should have_scheduled(anything, anything).at(scheduled_at)
      Person.should have_scheduled(anything, last_name).at(scheduled_at)
      Person.should have_scheduled(first_name, anything).at(scheduled_at)
    end

    it "returns false if the arguments are not found in the queue" do
      Person.should_not have_scheduled(last_name, first_name)
    end

    context "with #at(timestamp)" do
      it "returns true if arguments and timestamp matches positive expectation" do
        Person.should have_scheduled(first_name, last_name).at(scheduled_at)
      end

      it "returns true if arguments and timestamp matches negative expectation" do
        Person.should_not have_scheduled(first_name, last_name).at(scheduled_at + 5 * 60)
      end
    end

    context "with #in(interval)" do
      let(:interval) { 10 * 60 }

      before(:each) do
        Resque.enqueue_in(interval, Person, first_name, last_name)
      end

      it "returns true if arguments and interval matches positive expectation" do
        Person.should have_scheduled(first_name, last_name).in(interval)
      end

      it "returns true if arguments and interval matches negative expectation" do
        Person.should_not have_scheduled(first_name, last_name).in(interval + 5 * 60)
      end
    end
  end

  describe "#have_schedule_size_of" do
    before do
      Resque.enqueue_at(Time.now + 5 * 60, Person, first_name, last_name)
    end

    it "raises the approrpiate exception" do
      lambda {
        Person.should have_schedule_size_of(2)
      }.should raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it "returns true if actual schedule size matches positive expectation" do
      Person.should have_schedule_size_of(1)
    end

    it "returns true if actual schedule size matches negative expectation" do
      Person.should_not have_schedule_size_of(2)
    end
  end

  describe "#have_schedule_size_of_at_least" do
    before do
      Resque.enqueue_at(Time.now + 5 * 60, Person, first_name, last_name)
    end

    it "raises the approrpiate exception" do
      lambda {
        Person.should have_schedule_size_of_at_least(2)
      }.should raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    it "returns true if actual schedule size matches positive expectation" do
      Person.should have_schedule_size_of_at_least(1)
    end

    it "returns true if actual schedule size matches negative expectation" do
      Person.should_not have_schedule_size_of_at_least(5)
    end
  end
end
