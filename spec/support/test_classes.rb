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
  def self.perform(first_name, last_name)
  end

  def self.queue
    :people
  end
end
