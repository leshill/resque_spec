module ResqueSpec
  module Helpers

    def with_resque
      global = ResqueSpec.inline
      begin
        ResqueSpec.inline = true
        yield
      ensure
        ResqueSpec.inline = global
      end
    end

    def without_resque_spec
      global = ResqueSpec.disable_ext
      begin
        ResqueSpec.disable_ext = true
        yield
      ensure
        ResqueSpec.disable_ext = global
      end
    end

  end
end
