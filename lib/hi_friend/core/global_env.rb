module HiFriend::Core
  class GlobalEnv
    class << self
      def load!
        new.tap(&:load!)
      end
    end

    def load!
      load_stdlib_from_rbs
    end

    def consts
      # XXX: to be implemented
      []
    end

    def methods
      # XXX: to be implemented
      []
    end

    private def load_stdlib_from_rbs
      # XXX: to be implemented
    end
  end
end
