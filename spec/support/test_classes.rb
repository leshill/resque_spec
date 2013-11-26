class HookOrder
  class << self
    attr_accessor :invoked

    def after_enqueue(*args)
      raise "Enqueue called after perform!" if invoked
    end

    def perform(*args)
      self.invoked = true
    end

    def queue
      :hook_order
    end

    def reset!
      self.invoked = nil
    end
  end
end

class NameFromClassMethod
  class << self
    attr_accessor :invocations

    def perform(*args)
      self.invocations += 1
    end

    def queue
      :name_from_class_method
    end
  end

  self.invocations = 0
end

class FailingJob
  class << self
    def perform(*args)
      raise "failure!"
    end

    def queue
      :failing_job
    end
  end
end

class NoQueueClass
  class << self
    attr_accessor :invocations

    def perform(*args)
      self.invocations += 1
    end

  end

  self.invocations = 0
end

class NameFromInstanceVariable
  @queue = "name_from_instance_variable"
end

class Person
  class << self
    attr_accessor :afters, :arounds, :befores, :enqueues, :invocations, :before_enq

    def after_enqueue(*args)
      self.enqueues += 1
    end

    def after_perform(*args)
      self.afters += 1
    end

    def around_perform(*args)
      self.arounds += 1
      yield *args
    end

    def before_enqueue(*args)
      self.before_enq += 1
    end

    def before_perform(*args)
      self.befores += 1
    end

    def failures
      @failures ||= []
    end

    def on_failure(exception, *args)
      failures << exception
    end

    def perform(first_name, last_name)
      self.invocations += 1
    end

    def queue
      :people
    end
  end

  self.afters = 0
  self.arounds = 0
  self.befores = 0
  self.enqueues = 0
  self.invocations = 0
  self.before_enq = 0
end

class Place
  class << self
    def failures
      @failures ||= []
    end

    def on_failure(exception, *args)
      failures << exception
    end

    def perform(name)
      raise "OMG!"
    end

    def queue
      :places
    end
  end
end
