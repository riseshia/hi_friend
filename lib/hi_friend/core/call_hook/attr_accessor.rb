module HiFriend::Core
  module CallHook
    # attr_accessor to
    #   def {name} = @name
    #   def {name}=(name) = @name = name
    class AttrAccessor < Base
      def matched?(_const_name, method_name)
        method_name == "attr_accessor"
      end

      def call(visitor, node, &block)
        current_const_name = visitor.current_self_type_name
        const = visitor.const_registry.find(current_const_name)

        node.arguments&.arguments&.each do |arg_node|
          # Handle string or symbol only.
          if arg_node.respond_to?(:unescaped)
            # reader
            method_obj = visitor.method_registry.create(
              receiver_name: current_const_name,
              name: arg_node.unescaped,
              node: arg_node,
              path: visitor.source.path,
              singleton: visitor.current_in_singleton,
              visibility: :public,
              type: :attr_writer,
            )
            method_obj.receiver_obj(const)

            # writer
            method_name = "#{arg_node.unescaped}="
            method_obj = visitor.method_registry.create(
              receiver_name: current_const_name,
              name: method_name,
              node: arg_node,
              path: @file_path,
              singleton: @current_in_singleton,
              visibility: :public,
              type: :attr_writer,
            )
            method_obj.receiver_obj(const)
          else
            # Do nothing with arg node, such lvar.
          end
        end
      end
    end
  end
end
