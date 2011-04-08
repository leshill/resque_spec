require 'spec_helper'

describe ResqueSpec::Helpers do
  subject do
    Object.new.extend(ResqueSpec::Helpers)
  end

  before { ResqueSpec.reset! }

  describe "#with_resque" do

    it "performs job" do
      NameFromClassMethod.should_receive(:perform).with(1)
      subject.with_resque { Resque.enqueue(NameFromClassMethod, 1) }
    end

    it "does not add to the queue" do
      subject.with_resque { Resque.enqueue(NameFromClassMethod, 1) }
      ResqueSpec.queue_for(NameFromClassMethod).should be_empty
    end

    it "only performs jobs in block" do
      NameFromClassMethod.should_receive(:perform).with(1).once
      subject.with_resque { Resque.enqueue(NameFromClassMethod, 1) }
      Resque.enqueue(NameFromClassMethod, 1)
    end

    it "only adds to queue outside of block" do
      subject.with_resque { Resque.enqueue(NameFromClassMethod, 1) }
      Resque.enqueue(NameFromClassMethod, 1)
      ResqueSpec.queue_for(NameFromClassMethod).should have(1).item
    end
  end
end
