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
        ResqueSpec.queue_for(NameFromClassMethod).size.should eq(1)
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
        ResqueSpec.schedule_for(NameFromClassMethod).size.should eq(1)
      end
    end

    context "does not modify inline config" do
      [true, false].each do |status|
        describe "when inline is #{status}" do
          it "leaves inline as #{status}" do
            ResqueSpec.inline = status
            expect do
              with_resque do
                # do something
              end
            end.to_not change(ResqueSpec, :inline)
          end

          it "leaves inline as #{status} when it raises an exception" do
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
    context "does not modify disable_ext config" do
      [true, false].each do |status|
        describe "when disable_ext is #{status}" do
          it "leaves disable_ext as #{status}" do
            ResqueSpec.disable_ext = status
            expect do
              without_resque_spec do
                # do something
              end
            end.to_not change(ResqueSpec, :disable_ext)
          end

          it "leaves disable_ext as  #{status} when it raises an exception" do
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
