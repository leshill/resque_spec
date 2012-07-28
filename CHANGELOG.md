## 0.12.3 (2012-07-27)

* #57 - Fix bug in with\_resque and without\_resque helpers (@lellisga)

## 0.12.2 (2012-06-11)

* #56 - Fix handling of resque-scheduler API: does not allow Date to be used (uses to\_i for Redis keys)

## 0.12.1 (2012-05-22)

* Implement Resque.peek (@avdgaag)

## 0.12.0 (2012-05-21)

* Changed remove\_delayed to return number of removed items to match resque\_scheduler behaviour (@dtsiknis)
