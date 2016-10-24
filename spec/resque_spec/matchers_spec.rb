require 'spec_helper'

describe "ResqueSpec Matchers" do
  before do
    ResqueSpec.reset!
  end

  let(:first_name) { 'Les' }
  let(:last_name) { 'Hill' }

  describe "#be_queued" do
    context "queued with a class" do
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      subject { Person }

      it { should be_queued(first_name, last_name) }
      it { should_not be_queued(last_name, first_name) }
    end


    context "queued with any_args or *anything" do
      context "for no args" do
        before do
          Resque.enqueue(Person)
        end

        subject { Person }

        # anything does not match nothing
        it { should_not be_queued(anything) }
        # any_args matches no args
        it { should be_queued(any_args) }
      end

      context "for nil" do
        before do
          Resque.enqueue(Person, nil)
        end

        subject { Person }

        it { should be_queued(anything) }
        it { should be_queued(any_args) }
      end

      context "for a single non-nil parameter" do
        before do
          Resque.enqueue(Person, first_name)
        end

        subject { Person }

        it { should be_queued(any_args) }
        it { should be_queued(anything) }
      end

      context "for multiple parameters" do
        before do
          Resque.enqueue(Person, first_name, nil, [:foo])
        end

        subject { Person }

        it { should be_queued(anything, anything, anything).once }
        it { should be_queued(any_args) }
      end

      context "multiple times for any parameters" do
        before do
          Resque.enqueue(Person)
          Resque.enqueue(Person, first_name)
          Resque.enqueue(Person, first_name, nil, [:foo])
        end

        subject { Person }

        it { should be_queued(any_args) }
        it { should be_queued(any_args).times(3) }
      end
    end

    context "queued with a string" do
      before do
        Resque::Job.create(:people, "Person", first_name, last_name)
      end

      context "asserted with a class" do
        subject { Person }

        it { should be_queued(first_name, last_name) }
        it { should_not be_queued(last_name, first_name) }
      end

      context "asserted with a string" do
        subject { "Person" }

        it { should be_queued(first_name, last_name) }
        it { should_not be_queued(last_name, first_name) }
      end

      context "with anything matcher" do
        subject { "Person" }

        it { should be_queued(anything, anything) }
        it { should be_queued(anything, last_name) }
        it { should be_queued(first_name, anything) }
        it { should_not be_queued(anything) }
        it { should_not be_queued(anything, anything, anything) }
      end
    end

    context "#in" do

      before do
        Resque::Job.create(:people, "User", first_name, last_name)
      end

      subject { "User" }

      context "without #in(queue_name)" do
        it "should raise a Resque::NoQueueError" do
          lambda { "User".should be_queued(first_name, last_name) }.should raise_error(Resque::NoQueueError)
        end
      end

      context "with #in(queue_name)" do
        it { should be_queued(first_name, last_name).in(:people) }
        it { should_not be_queued(last_name, first_name).in(:people) }
      end

      context "without #in(:places) after #in(:people)" do
        before { should be_queued(first_name, last_name).in(:people) }
        before { Resque.enqueue(Place) }

        specify { Place.should be_queued }
      end
    end

    context "#times" do

      subject { Person }

      context "job queued once" do
        before do
          Resque.enqueue(Person, first_name, last_name)
        end

        it { should_not be_queued(first_name, last_name).times(0) }
        it { should be_queued(first_name, last_name).times(1) }
        it { should_not be_queued(first_name, last_name).times(2) }
      end

      context "no job queued" do
        it { should be_queued(first_name, last_name).times(0) }
        it { should_not be_queued(first_name, last_name).times(1) }
      end
    end

    context "#once" do

      subject { Person }

      context "job queued once" do
        before do
          Resque.enqueue(Person, first_name, last_name)
        end

        it { should be_queued(first_name, last_name).once }
      end

      context "no job queued" do
        it { should_not be_queued(first_name, last_name).once }
      end
    end
  end

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

    context "with #at_or_in(timestamp, interval)" do
      let(:interval) { 10 * 60 }
      let(:scheduled_at) { Time.now + 30 * 60 }

      context "scheduling with #enqueue_in" do
        before(:each) do
          Resque.enqueue_in(interval, Person, first_name, last_name)
        end

        it "returns true if arguments, timestamp or interval matches positive expectation" do
          Person.should have_scheduled(first_name, last_name).at_or_in(scheduled_at, interval)
        end

        it "returns true if arguments, timestamp, and interval matches negative expectation" do
          Person.should_not have_scheduled(first_name, last_name).at_or_in(Time.now + 60 * 60, 100 * 60)
        end
      end

      context "scheduling with #enqueue_at" do
        before(:each) do
          Resque.enqueue_at(scheduled_at, Person, first_name, last_name)
        end

        it "returns true if arguments, timestamp or interval matches positive expectation" do
          Person.should have_scheduled(first_name, last_name).at_or_in(scheduled_at, interval)
        end

        it "returns true if arguments, timestamp, and interval matches negative expectation" do
          Person.should_not have_scheduled(first_name, last_name).at_or_in(Time.now + 60 * 60, 100 * 60)
        end
      end
    end

    context "with #queue(queue_name)" do
      let(:interval) { 10 * 60 }

      before(:each) do
        Resque.enqueue_in_with_queue(:test_queue, interval, NoQueueClass, 1)
      end

      it "uses queue from chained method" do
        NoQueueClass.should have_scheduled(1).in(interval).queue(:test_queue)
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

    context "with #queue(queue_name)" do
      before(:each) do
        Resque.enqueue_in_with_queue(:test_queue, 10 * 60, NoQueueClass, 1)
      end

      it "returns true if actual schedule size matches positive expectation" do
        NoQueueClass.should have_schedule_size_of(1).queue(:test_queue)
      end
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

    context "with #queue(queue_name)" do
      before(:each) do
        Resque.enqueue_in_with_queue(:test_queue, 10 * 60, NoQueueClass, 1)
      end

      it "returns true if actual schedule size matches positive expectation" do
        NoQueueClass.should have_schedule_size_of_at_least(1).queue(:test_queue)
      end
    end

  end
end
