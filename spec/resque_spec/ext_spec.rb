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
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      it "adds to the queue for the given class" do
        ResqueSpec.queue_for(Person).should_not be_empty
      end
    end

    describe '#peek' do
      before do
        Resque.enqueue(Person, first_name, last_name)
      end

      it 'should return the queued task' do
        Resque.peek(:people).size.should eq(1)
      end

      it 'should return a job with string keys' do
        job = Resque.peek(:people).first
        job.should have_key('args')
        job.should have_key('class')
      end
    end

    describe "#enqueue_to" do
      context "successfully queues" do
        subject do
          Resque.enqueue_to(:specified, Person, first_name, last_name)
        end

        it "adds to the queue hash" do
          subject
          ResqueSpec.queue_by_name(:specified).should_not be_empty
        end

        it "sets the klass on the queue" do
          subject
          ResqueSpec.queue_by_name(:specified).last.should include(:class => Person.to_s)
        end

        it "sets the arguments on the queue" do
          subject
          ResqueSpec.queue_by_name(:specified).last.should include(:args => [first_name, last_name])
        end

        it { should eq(true) }
      end

      context "hooks" do
        it "calls the after_enqueue hook" do
          expect {
            Resque.enqueue(Person, first_name, last_name)
          }.to change(Person, :enqueues).by(1)
        end

        it "calls the before_enqueue hook" do
          expect {
            Resque.enqueue(Person, first_name, last_name)
          }.to change(Person, :before_enq).by(1)
        end

        context "a before enqueue hook returns false" do
          before do
            Person.stub(:before_enqueue).and_return(false)
          end

          it "will not call the after_enqueue hook" do
            expect {
              Resque.enqueue(Person, first_name, last_name)
            }.not_to change(Person, :enqueues)
          end

          it "did not queue a job" do
            ResqueSpec.reset!
            Resque.enqueue(Person, first_name, last_name)
            ResqueSpec.queue_for(Person).count.should == 0
          end

          it "returns nil" do
            ResqueSpec.reset!
            Resque.enqueue(Person, first_name, last_name).should be_nil
          end
        end

        context "when inline" do
          it "calls the after_enqueue hook before performing" do
            HookOrder.reset!
            expect {
              with_resque { Resque.enqueue(HookOrder, 1) }
            }.not_to raise_error
          end

          it "calls the before_enqueue hook" do
            expect {
              with_resque { Resque.enqueue(Person, first_name, last_name) }
            }.to change(Person, :before_enq)
          end

          it "calls the before_perform hook" do
            expect {
              with_resque { Resque.enqueue(Person, first_name, last_name) }
            }.to change(Person, :befores).by(1)
          end

          it "calls the around_perform hook" do
            expect {
              with_resque { Resque.enqueue(Person, first_name, last_name) }
            }.to change(Person, :befores).by(1)
          end

          it "calls the after_perform hook" do
            expect {
              with_resque { Resque.enqueue(Person, first_name, last_name) }
            }.to change(Person, :befores).by(1)
          end

          context "a before enqueue hook returns false" do
            before do
              Person.stub(:before_enqueue).and_return(false)
            end

            it "does not call the before_perform hook" do
              expect {
                with_resque { Resque.enqueue(Person, first_name, last_name) }
              }.not_to change(Person, :befores)
            end

            it "does not call the around_perform hook" do
              expect {
                with_resque { Resque.enqueue(Person, first_name, last_name) }
              }.not_to change(Person, :befores)
            end

            it "does not call the after_perform hook" do
              expect {
                with_resque { Resque.enqueue(Person, first_name, last_name) }
              }.not_to change(Person, :befores)
            end

            it "does not call the after_enqueue hook" do
              expect {
                Resque.enqueue(Person, first_name, last_name)
              }.not_to change(Person, :enqueues)
            end

            it "does not perform the job" do
              expect {
                Resque.enqueue(Person, first_name, last_name)
              }.not_to change(Person, :invocations)
            end
          end

          context "a failure occurs" do
            it "calls the on_failure hook" do
              expect {
                with_resque { Resque.enqueue(Place, last_name) } rescue nil
              }.to change(Place.failures, :size).by(1)
            end
          end
        end
      end
    end

    describe "#dequeue" do
      if Resque::VERSION > "1.19.0"
        describe "without arguments" do
          it "should remove all items from queue with the given class" do
            ResqueSpec.queue_for(Person).count.should == 3
            expect do
              Resque.dequeue(Person)
            end.to change(ResqueSpec.queue_for(Person), :count).by(-3)
            ResqueSpec.queue_for(Person).count.should == 0
          end
        end

        describe "with arguments" do
          it "should remove items from queue with the given class and arguments" do
            ResqueSpec.queue_for(Person).count.should == 3
            expect do
              Resque.dequeue(Person, "xyz", "lmn")
            end.to change(ResqueSpec.queue_for(Person), :size).by(-2)
            ResqueSpec.queue_for(Person).count.should == 1
          end
        end
      else
        describe "without arguments" do
          it "should remove all items from queue with the given class" do
            ResqueSpec.queue_for(Person).count.should == 3
            expect do
              Resque.dequeue(Person).should == 3
            end.to change(ResqueSpec.queue_for(Person), :count).by(-3)
            ResqueSpec.queue_for(Person).count.should == 0
          end
        end

        describe "with arguments" do
          it "should remove items from queue with the given class and arguments" do
            ResqueSpec.queue_for(Person).count.should == 3
            expect do
              Resque.dequeue(Person, "xyz", "lmn").should == 2
            end.to change(ResqueSpec.queue_for(Person), :size).by(-2)
            ResqueSpec.queue_for(Person).count.should == 1
          end
        end
      end
    end

    describe "#reserve" do

      subject { Resque.reserve(queue_name) }

      context "given an invalid queue" do
        let(:queue_name) { :not_a_queue }

        it { should be_nil }
      end

      context "given a valid queue" do
        before do
          Resque.enqueue(Person, 'Dutch', 'Schaefer')
        end

        let(:queue_name) { Person.queue }

        context "and no jobs" do
          before do
            Resque.dequeue(Person)
          end

          it { should be_nil }
        end

        context "and at least one job" do
          it { should be_kind_of(Resque::Job) }

          it "reduced the size of the queue" do
            expect do
              subject
            end.to change(ResqueSpec.queue_for(Person), :count).by(-1)
          end
        end
      end
    end

    describe "#size" do
      context "given a valid queue" do
        subject { Resque.size(Person.queue) }
        it { should eq(3) }
      end
      context "given an invalid queue" do
        subject { Resque.size("not_a_queue")}
        it { should eq(0) }
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
        ResqueSpec.queue_by_name(:people).should_not be_empty
      end

      it "sets the klass on the queue" do
        ResqueSpec.queue_by_name(:people).last.should include(:class => Person.to_s)
      end

      it "sets the arguments on the queue" do
        ResqueSpec.queue_by_name(:people).last.should include(:args => [first_name, last_name])
      end
    end

    describe "#destroy" do
      describe "without arguments" do
        it "should remove all items from queue with the given class" do
          ResqueSpec.queue_for(Person).count.should == 3
          expect do
            Resque::Job.destroy(:people, Person).should == 3
          end.to change(ResqueSpec.queue_for(Person), :count).by(-3)
          ResqueSpec.queue_for(Person).count.should == 0
        end
      end

      describe "with arguments" do
        it "should remove items from queue with the given class and arguments" do
          ResqueSpec.queue_for(Person).count.should == 3
          expect do
            Resque::Job.destroy(:people, Person, "xyz", "lmn").should == 2
          end.to change(ResqueSpec.queue_for(Person), :size).by(-2)
          ResqueSpec.queue_for(Person).count.should == 1
        end
      end
    end
  end

  context "when disable_ext is set to get the default behavior of Resque" do
    around { |example| without_resque_spec { example.run } }

    describe "Resque" do
      describe ".enqueue" do
        it "calls the original Resque.enqueue method" do
          Resque.should_receive(:enqueue_without_resque_spec).with(Person, first_name, last_name)
          Resque.enqueue(Person, first_name, last_name)
        end
      end

      describe ".enqueue_to" do
        it "calls the original Resque.enqueue_to method" do
          Resque.should_receive(:enqueue_to_without_resque_spec).with(:specified, Person, first_name, last_name)
          Resque.enqueue_to(:specified, Person, first_name, last_name)
        end
      end

      describe ".reserve" do
        it "calls the original Resque::Job.reserve method" do
          if Resque.respond_to? :reserve
            Resque::Job.should_receive(:reserve_without_resque_spec).with(Person.queue)
            Resque.reserve(Person.queue)
          else
            pending "Only in Resque 1.x"
          end
        end
      end
    end

    describe "Resque::Job" do
      describe ".create" do
        it "calls the original Resque::Job.create method" do
          Resque::Job.should_receive(:create_without_resque_spec).with(:people, Person, first_name, last_name)
          Resque::Job.create(:people, Person, first_name, last_name)
        end
      end

      describe ".destroy" do
        it "calls the original Resque::Job.destroy method" do
          Resque::Job.should_receive(:destroy_without_resque_spec).with(:people, Person, first_name, last_name)
          Resque::Job.destroy(:people, Person, first_name, last_name)
        end
      end
    end

    describe ".reserve" do
      it "calls the original Resque.reserve method" do
        Resque::Job.should_receive(:reserve_without_resque_spec).with(Person.queue)
        Resque::Job.reserve(Person.queue)
      end
    end
  end
end
