require 'spec_helper'

describe ResqueSpec::Helpers do
  extend ResqueSpec::Helpers

  before { ResqueSpec.reset! }

  describe "#with_resque" do

    context "Resque#enqueue" do
      subject do
        with_resque do
          Resque.enqueue(NameFromClassMethod, 1)
        end
      end

      it "performs job" do
        NameFromClassMethod.should_receive(:perform).with(1)
        subject
      end

      it "does not add to the queue" do
        subject
        ResqueSpec.queue_for(NameFromClassMethod).should be_empty
      end

      it "only performs jobs in block" do
        NameFromClassMethod.should_receive(:perform).with(1).once
        subject
        Resque.enqueue(NameFromClassMethod, 1)
      end

      it "only adds to queue outside of block" do
        subject
        Resque.enqueue(NameFromClassMethod, 1)
        ResqueSpec.queue_for(NameFromClassMethod).should have(1).item
      end
    end

    context "Resque#enqueue_at" do
      subject do
        with_resque do
          Resque.enqueue_at(Time.now + 500, NameFromClassMethod, 1)
        end
      end

      it "performs job" do
        NameFromClassMethod.should_receive(:perform).with(1)
        subject
      end

      it "does not add to the queue" do
        subject
        ResqueSpec.schedule_for(NameFromClassMethod).should be_empty
      end

      it "only performs jobs in block" do
        NameFromClassMethod.should_receive(:perform).with(1).once
        subject
        Resque.enqueue_at(Time.now + 600, NameFromClassMethod, 1)
      end

      it "only adds to queue outside of block" do
        subject
        Resque.enqueue_at(Time.now + 600, NameFromClassMethod, 1)
        ResqueSpec.schedule_for(NameFromClassMethod).should have(1).item
      end
    end

    context "shouldn't edit global variable" do
      [true, false].each do |status|
        describe "when global variable is #{status}" do

          it "keeps global variable #{status}" do
            ResqueSpec.inline = status
            with_resque do
              # do something
            end
            ResqueSpec.inline.should eq status
          end

          it "keeps global variable #{status} when it raises an exception" do
            ResqueSpec.inline = status
            begin
              with_resque do
                raise "here's an exception"
              end
            rescue
            end
            ResqueSpec.inline.should eq status
          end
        end
      end
    end
  end

  describe "#without_resque_spec" do
    context "shouldn't edit global variable" do
      [true, false].each do |status|
        describe "when global variable is #{status}" do

          it "keeps global variable #{status}" do
            ResqueSpec.disable_ext = status
            without_resque_spec do
              # do something
            end
            ResqueSpec.disable_ext.should eq status
          end

          it "keeps global variable #{status} when it raises an exception" do
            ResqueSpec.inline = status
            begin
              with_resque do
                raise "here's an exception"
              end
            rescue
            end
            ResqueSpec.inline.should eq status
          end
        end
      end
    end
  end
end
