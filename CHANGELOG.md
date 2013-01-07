## 0.13.0 (2013-01-07)

* #9 - Add `resque_spec/cucumber` to expose `with_resque` helpers to `World`

## 0.12.7 (2012-12-04)

* #66 - Add support for enqueue_at_with_queue/enqueue_in_with_queue (@k1w1)

## 0.12.6 (2012-11-21)

* #65 - Add `have_queue_size_of_at_least` and `have_schedule_size_of_at_least` matchers (@heelhook)

## 0.12.5 (2012-11-04)

* #61 - Fix DST problem in `have\_scheduled` (@opinel)
* #62 - Add `times` chained matcher "it { should have\_queued(first\_name, last\_name).times(1) }" (@lukemelia)

## 0.12.4 (2012-10-19)

* #60 - `Resque.size` support (@jeffdeville)

## 0.12.3 (2012-07-27)

* #57 - Fix bug in with\_resque and without\_resque helpers (@lellisga)

## 0.12.2 (2012-06-11)

* #56 - Fix handling of resque-scheduler API: does not allow Date to be used (uses to\_i for Redis keys)

## 0.12.1 (2012-05-22)

* Implement Resque.peek (@avdgaag)

## 0.12.0 (2012-05-21)

* Changed remove\_delayed to return number of removed items to match resque\_scheduler behaviour (@dtsiknis)
