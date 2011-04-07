require 'spec_helper'

describe ResqueSpec::Helpers do
  subject do
    Object.new.extend(ResqueSpec::Helpers)
  end

  before { ResqueSpec.reset! }

  describe "#with_resque" do

    it "performs job" do
      Person.should_receive(:perform).with(1)
      subject.with_resque { Resque.enqueue(Person, 1) }
    end

    it "does not add to the queue" do
      subject.with_resque { Resque.enqueue(Person, 1) }
      ResqueSpec.queue_for(Person).should be_empty
    end

    it "only performs jobs in block" do
      Person.should_receive(:perform).with(1).once
      subject.with_resque { Resque.enqueue(Person, 1) }
      Resque.enqueue(Person, 1)
    end

    it "only adds to queue outside of block" do
      subject.with_resque { Resque.enqueue(Person, 1) }
      Resque.enqueue(Person, 1)
      ResqueSpec.queue_for(Person).should have(1).item
    end
  end
end
