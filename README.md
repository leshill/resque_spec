ResqueSpec
==========

A simple RSpec and Cucumber matcher for Resque.enqueue and Resque.enqueue_at (from `ResqueScheduler`), loosely based on
[http://github.com/justinweiss/resque_unit](http://github.com/justinweiss/resque_unit).

This should work with Resque v1.6.0 and up and RSpec v1.3.0 and up.

Install
-------

Install the gem

    % gem install resque_spec

And update your Gemfile (Not using bundler? Do the necessary thing for
your app's gem management)

    group :test do
      gem 'resque_spec'
    end

Resque with Specs
-----------------

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

ResqueScheduler with Specs
--------------------------

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

Copyright (c) 2010 Les Hill. See LICENSE for details.
