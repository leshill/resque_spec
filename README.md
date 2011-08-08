ResqueSpec
==========

A simple RSpec and Cucumber matcher for Resque.enqueue and
Resque.enqueue_at/enqueue_in (from `ResqueScheduler`), loosely based on
[http://github.com/justinweiss/resque_unit](http://github.com/justinweiss/resque_unit).

ResqueSpec will also fire Resque hooks if you are using them. See below.

This should work with `Resque v1.15.0` and up and `RSpec v2.5.0` and up.

If you are using `RSpec ~> 1.3.0`, you should use version `~> 0.2.0`. This
branch is not actively maintained.

Install
-------

Update your Gemfile to include `resque_spec` only in the *test* group (Not using
`bundler`? Do the necessary thing for your app's gem management and use
`bundler`. `resque_spec` is a mock API, it should only be used with your tests!)

    group :test do
      gem 'resque_spec'
    end

Resque with Specs
=================

Given this scenario

    Given a person
    When I recalculate
    Then the person has calculate queued

And I write this spec using the `resque_spec` matcher

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the Person queue" do
        person.recalculate
        Person.should have_queued(person.id, :calculate)
      end
    end

(And I take note of the `before` block that is calling `reset!` for every spec)

And I might use the `in` statement to specify the queue:

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the Person queue" do
        person.recalculate
        Person.should have_queued(person.id, :calculate).in(:people)
      end
    end

And I might write this as a Cucumber step

    Then /the (\w?) has (\w?) queued/ do |thing, method|
      thing_obj = instance_variable_get("@#{thing}")
      thing_obj.class.should have_queued(thing_obj.id, method.to_sym)
    end

Then I write some code to make it pass:

    class Person
      @queue = :people

      def recalculate
        Resque.enqueue(Person, id, :calculate)
      end
    end

ResqueMailer with Specs
=======================

To use with [ResqueMailer](https://github.com/zapnap/resque_mailer) you should
have an initializer that does *not* exclude the `test` (or `cucumber`)
environment. Your initializer will probably end up looking like:

    # config/initializers/resque_mailer.rb
    Resque::Mailer.excluded_environments = []

ResqueScheduler with Specs
==========================

To use with ResqueScheduler, add this require `require 'resque_spec/scheduler'`

Given this scenario

    Given a person
    When I schedule a recalculate
    Then the person has calculate scheduled

And I write this spec using the `resque_spec` matcher

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the Person queue" do
        person.recalculate
        Person.should have_scheduled(person.id, :calculate)
      end
    end

(And I take note of the `before` block that is calling `reset!` for every spec)

*(There is also a **have_scheduled_at** matcher)*

And I might write this as a Cucumber step

    Then /the (\w?) has (\w?) scheduled/ do |thing, method|
      thing_obj = instance_variable_get("@#{thing}")
      thing_obj.class.should have_scheduled(thing_obj.id, method.to_sym)
    end

Then I write some code to make it pass:

    class Person
      @queue = :people

      def recalculate
        Resque.enqueue_at(Time.now + 3600, Person, id, :calculate)
      end
    end

Queue Size Specs
================

You can check the size of the queue in your specs too.

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds an entry to the Person queue" do
        person.recalculate
        Person.should have_queue_size_of(1)
      end
    end

Performing Jobs in Specs
========================

Normally, Resque does not perform queued jobs within tests. You may want to
make assertions based on the result of your jobs. ResqueSpec can process jobs
immediately as they are queued or under your control.

Performing jobs immediately
---------------------------

To perform jobs immediately, you can pass a block to the `with_resque` helper:

Given this scenario

    Given a game
    When I score
    Then the game has a score

I might write this as a Cucumber step

    When /I score/ do
      with_resque do
        visit game_path
        click_link 'Score!'
      end
    end

Or I write this spec using the `with_resque` helper

    describe "#score!" do
      before do
        ResqueSpec.reset!
      end

      it "increases the score" do
        with_resque do
          game.score!
        end
        game.score.should == 10
      end
    end

You can turn this behavior on by setting `ResqueSpec.inline = true`.

Performing jobs at your discretion
----------------------------------

You can perform the first job on a queue at a time, or perform all the jobs on
a queue.  Use `ResqueSpec#perform_next(queue_name)` or
`ResqueSpec#perform_all(queue_name)`

Given this scenario:

    Given a game
    When I score
    And the score queue runs
    Then the game has a score

I might write this as a Cucumber step

    When /the (\w+) queue runs/ do |queue_name|
      ResqueSpec.perform_all(queue_name)
    end

Hooks
=====

Resque provides hooks at different points of the queueing lifecylce.  ResqueSpec fires these hooks when appropriate.

The after enqueue hook is always called when you use `Resque#enqueue`.

The `perform` hooks: before, around, after, and on failure are fired by
ResqueSpec if you are using the `with_resque` helper or set `ResqueSpec.inline = true`.

Important! `Resque#enqueue_at/enqueue_in` does not fire the after enqueue hook (the job has not been queued yet!), but will fire the `perform` hooks if you are using `inline` mode.

Note on Patches/Pull Requests
=============================

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
=========

Copyright (c) 2010-2011 Les Hill. See LICENSE for details.
