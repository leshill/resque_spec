module ResqueSpec
  module Helpers

    def with_resque
      original = ResqueSpec.inline
      begin
        ResqueSpec.inline = true
        yield
      ensure
        ResqueSpec.inline = original
      end
    end

    def without_resque_spec
      original = ResqueSpec.disable_ext
      begin
        ResqueSpec.disable_ext = true
        yield
      ensure
        ResqueSpec.disable_ext = original
      end
    end

  end
end
