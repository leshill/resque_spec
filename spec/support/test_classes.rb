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

class NameFromInstanceVariable
  @queue = "name_from_instance_variable"
end

class Person
  class << self
    attr_accessor :enqueues, :invocations

    def after_enqueue(*args)
      self.enqueues += 1
    end

    def perform(first_name, last_name)
      self.invocations += 1
    end

    def queue
      :people
    end
  end

  self.enqueues = 0
  self.invocations = 0
end
