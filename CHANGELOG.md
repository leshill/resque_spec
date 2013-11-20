## On master

# 0.14.4 (2013-11-20)

* #87 - Add 'be\_queued' matcher that behaves like 'have\_queued' (@eclubb)

# 0.14.3 (2013-11-13)

* #82 - Add Travis CI to repo (@dickeyxxx)
* #81 - Fix Resque 2.0 warnings (@dickeyxxx)
* Use pry instead of debugger

## 0.14.2 (2013-08-10)

* #76 - Loosen rubygems version constraint (@Empact)

## 0.14.1 (2013-08-07)

* #75 - Add license statement to gemspec

## 0.14.0 (2013-08-07)

* Add ResqueMailer examples to README (@yuyak)
* #70 - RSpec 2.1x support (@ozeias)
* #73 - Replace `rspec` dependency with explicit dependencies (@andresbravog)

## 0.13.0 (2013-01-07)

* #9 - Add `resque_spec/cucumber` to expose `with_resque` helpers to `World`

## 0.12.7 (2012-12-04)

* #66 - Add support for `enqueue_at_with_queue` and `enqueue_in_with_queue` (@k1w1)

## 0.12.6 (2012-11-21)

* #65 - Add `have_queue_size_of_at_least` and `have_schedule_size_of_at_least` matchers (@heelhook)

## 0.12.5 (2012-11-04)

* #61 - Fix DST problem in `have_scheduled` (@opinel)
* #62 - Add `times` chained matcher `it { should have_queued(first_name, last_name).times(1) }` (@lukemelia)

## 0.12.4 (2012-10-19)

* #60 - `Resque.size` support (@jeffdeville)

## 0.12.3 (2012-07-27)

* #57 - Fix bug in `with_resque` and `without_resque` helpers (@lellisga)

## 0.12.2 (2012-06-11)

* #56 - Fix handling of resque-scheduler API: does not allow Date to be used (uses `to_i` for Redis keys)

## 0.12.1 (2012-05-22)

* Implement Resque.peek (@avdgaag)

## 0.12.0 (2012-05-21)

* Changed `remove_delayed` to return number of removed items to match resque-scheduler behaviour (@dtsiknis)
