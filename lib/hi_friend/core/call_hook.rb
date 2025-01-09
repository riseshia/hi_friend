module HiFriend::Core
  module CallHook
    class << self
      def registered
        @registered ||= []
      end

      # Fetch the hook that matches the current call.
      # Notice that this method will return hook that matches only the first matched one.
      def fetch_matched_hook(current_const_name, method_name)
        hook = registered.find do |hook|
          hook.matched?(current_const_name, method_name)
        end
        return hook if hook

        raise "No hook found for call #{method_name} on #{current_const_name}."
      end

      def register(klass)
        registered << klass.new
      end
    end

    # Base class for call hooks.
    # Each call hook should inherit this class, this will:
    # - Register the hook automatically
    # - Provide a base interface for the hook
    class Base
      # matched? should return true if the hook should be called for the given method.
      # @return bool
      def matched?(_const_name, _method_name)
        raise NotImplementedError
      end

      # call should implement the logic for the hook.
      #
      # @param visitor [HiFriend::Core::Visitor]
      # @param node [Parser::AST::Node]
      # @param block [Proc] The block to delegate execution to visitor super.
      def call(visitor, node, &block)
        raise NotImplementedError
      end

      def self.inherited(klass)
        CallHook.register(klass)
      end
    end
  end
end
