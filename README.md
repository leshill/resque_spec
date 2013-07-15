ResqueSpec
==========

A test double of Resque for RSpec and Cucumber. The code was originally based
on
[http://github.com/justinweiss/resque_unit](http://github.com/justinweiss/resque_unit).

ResqueSpec will also fire Resque hooks if you are using them. See below.

The current version works with `Resque v1.19.0` and up and `RSpec v2.5.0` and up.

Install
-------

Update your Gemfile to include `resque_spec` only in the *test* group (Not
using `bundler`? Do the necessary thing for your app's gem management and use
`bundler`. `resque_spec` monkey patches `resque` it should only be used with
your tests!)

    group :test do
      gem 'resque_spec'
    end

Cucumber
--------

By default, the above will add the `ResqueSpec` module and make it available in
Cucumber. If you want the `with_resque` and `without_resque` helpers, manually
require the `resque_spec/cucumber` module:

    require 'resque_spec/cucumber'

This can be done in `features/support/env.rb` or in a specific support file
such as `features/support/resque.rb`.

What is ResqueSpec?
===================

ResqueSpec implements the *stable API* for Resque 1.19+ (which is `enqueue`,
`enqueue_to`,  `dequeue`, `peek`, `reserve`, `size`, the Resque hooks, and
because of the way `resque_scheduler` works `Job.create` and `Job.destroy`).

It does not have a test double for Redis, so this may lead to some interesting and
puzzling behaviour if you use some of the popular Resque plugins (such as
`resque_lock`).

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


And I see that the `have_queued` assertion is asserting that the `Person` queue has a job with arguments `person.id` and `:calculate`

And I take note of the `before` block that is calling `reset!` for every spec

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

Turning off ResqueSpec and calling directly to Resque
-----------------------------------------------------

Occasionally, you want to run your specs directly against Resque instead of
ResqueSpec. For one at a time use, pass a block to the `without_resque_spec`
helper:

    describe "#recalculate" do
      it "recalculates the persons score" do
        without_resque_spec do
          person.recalculate
        end
        ... assert recalculation after job done
      end
    end

Or you can manage when ResqueSpec is disabled by flipping the
`ResqueSpec.disable_ext` flag:

    # disable ResqueSpec
    ResqueSpec.disable_ext = true

You will most likely (but not always, see the Resque docs) need to ensure that
you have `redis` running.

ResqueMailer with Specs
=======================

To use with [ResqueMailer](https://github.com/zapnap/resque_mailer) you should
have an initializer that does *not* exclude the `test` (or `cucumber`)
environment. Your initializer will probably end up looking like:

    # config/initializers/resque_mailer.rb
    Resque::Mailer.excluded_environments = []

If you have a mailer like this:

    class ExampleMailer < ActionMailer::Base
      include Resque::Mailer

      def welcome_email(user_id)
      end
    end

You can write a spec like this:

    describe "#welcome_email" do
      before do
        ResqueSpec.reset!
        Examplemailer.welcome_email(user.id).deliver
      end

      subject { described_class }
      it { should have_queue_size_of(1) }
      it { should have_queued(:welcome_email, user.id) }
    end

resque-scheduler with Specs
==========================

To use with resque-scheduler, add this require `require 'resque_spec/scheduler'`

*n.b.* Yes, you also need to require resque-scheduler, this works (check the docs for other ways):

    gem "resque-scheduler", :require => "resque_scheduler"

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

And I might use the `at` statement to specify the time:

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the Person queue" do
        person.recalculate

        # Is it scheduled to be executed at 2010-02-14 06:00:00 ?
        Person.should have_scheduled(person.id, :calculate).at(Time.mktime(2010,2,14,6,0,0))
      end
    end

And I might use the `in` statement to specify time interval (in seconds):

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the Person queue" do
        person.recalculate

        # Is it scheduled to be executed in 5 minutes?
        Person.should have_scheduled(person.id, :calculate).in(5 * 60)
      end
    end

You can also check the size of the schedule:

    describe "#recalculate" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the Person queue" do
        person.recalculate

        Person.should have_schedule_size_of(1)
      end
    end

(And I take note of the `before` block that is calling `reset!` for every spec)

You can explicitly specify the queue when using enqueue_at_with_queue and
enqueue_in_with_queue:

    describe "#recalculate_in_future" do
      before do
        ResqueSpec.reset!
      end

      it "adds person.calculate to the :future queue" do
        person.recalculate_in_future

        Person.should have_schedule_size_of(1).queue(:future)
      end
    end

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

      def recalculate_in_future
        Resque.enqueue_at_with_queue(:future, Time.now + 3600, Person, id, :calculate)
      end
    end

Performing Jobs in Specs
========================

Normally, ResqueSpec does not perform queued jobs within tests. You may want to
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

Resque provides hooks at different points of the queueing lifecylce.
ResqueSpec fires these hooks when appropriate.

The before and after `enqueue` hooks are always called when you use
`Resque#enqueue`. If your `before_enqueue` hook returns `false`, the job will
not be queued and `after_enqueue` will not be called.

The `perform` hooks: before, around, after, and on failure are fired by
ResqueSpec if you are using the `with_resque` helper or set `ResqueSpec.inline = true`.

Important! If you are using resque-scheduler, `Resque#enqueue_at/enqueue_in`
does not fire the after enqueue hook (the job has not been queued yet!), but
will fire the `perform` hooks if you are using `inline` mode.

Note on Patches/Pull Requests
=============================

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Author
======

I made `resque_spec` because **resque** is awesome and should be easy to spec.
Follow me on [Github](https://github.com/leshill) and
[Twitter](https://twitter.com/leshill).

Contributors
============

* Kenneth Kalmer     (@kennethkalmer) : rspec dependency fix
* Brian Cardarella   (@bcardarella)   : fix mutation bug
* Joshua Davey       (@joshdavey)     : with\_resque helper
* Lar Van Der Jagt   (@supaspoida)    : with\_resque helper
* Evan Sagge         (@evansagge)     : Hook in via Job.create, have\_queued.in
* Jon Larkowski      (@l4rk)          : inline perform
* James Conroy-Finn  (@jcf)           : spec fix
* Dennis Walters     (@ess)           : enqueue\_in support
*                    (@RipTheJacker)  : remove\_delayed support
* Kurt Werle         (@kwerle)        : explicit require spec for v020
*                    (@dwilkie)       : initial before\_enqueue support
* Marcin Balinski    (@marcinb)       : have\_schedule\_size\_of matcher, schedule matcher at, in
*                    (@alexeits)      : fix matcher in bug with RSpec 2.8.0
*                    (@ToadJamb)      : encode/decode of Resque job arguments
* Mateusz Konikowski (@mkonikowski)   : support for anything matcher
* Mathieu Ravaux     (@mathieuravaux) : without\_resque\_spec support
* Arjan van der Gaag (@avdgaag)       : peek support
*                    (@dtsiknis)      : Updated removed\_delayed
* Li Ellis Gallardo  (@lellisga)      : fix inline/disable\_ext bug
* Jeff Deville       (@jeffdeville)   : Resque.size
* Frank Wambutt      (@opinel)        : Fix DST problem in `have\_scheduled`
* Luke Melia         (@lukemelia)     : Add `times` chained matcher
* Pablo Fernandez    (@heelhook)      : Add `have_queue_size_of_at_least` and `have_schedule_size_of_at_least` matchers
*                    (@k1w1)          : Add support for enqueue_at_with_queue/enqueue_in_with_queue
* Ozéias Sant'ana    (@ozeias)        : Update specs to RSpec 2.10

Copyright
=========

Copyright (c) 2010-2012 Les Hill. See LICENSE for details.
