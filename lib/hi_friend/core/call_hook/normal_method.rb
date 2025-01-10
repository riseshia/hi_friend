module HiFriend::Core
  module CallHook
    # Match to all method which is not matched by other special hooks
    class NormalMethod < Base
      def matched?(_const_name, _method_name)
        true
      end

      def call(visitor, node, &block)
        current_const_name = visitor.current_self_type_name
        const = visitor.const_registry.find(current_const_name)

        call_tv = visitor.find_or_create_tv(node)

        self_type = Type.const(current_const_name, singleton: visitor.current_in_singleton)
        call_tv.self_type_of_context(self_type)
        if node.receiver
          receiver_tv = visitor.find_or_create_tv(node.receiver)
          receiver_tv.received_methods.push(call_tv.name)
          call_tv.add_receiver_tv(receiver_tv)
        else # receiver is implicit self
          call_tv.add_receiver_type(self_type)
        end

        node.arguments&.arguments&.each do |arg|
          arg_tv = visitor.find_or_create_tv(arg)
          call_tv.add_arg_tv(arg_tv)
        end

        block.call

        visitor.last_evaluated_tv(call_tv)
      end
    end
  end
end
