module ResqueSpec
  module Helpers

    def with_resque
      begin
        ResqueSpec.inline = true
        yield
      ensure
        ResqueSpec.inline = false
      end
    end
  end
end
