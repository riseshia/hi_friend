module HiFriend::Core
  module CallHook
    # public:
    # - change the visibility of the method to public
    # - set the visibility of given method to public
    # - set the visibility of methods of given name to public
    class Public < Base
      def matched?(_const_name, method_name)
        method_name == "public"
      end

      def call(visitor, node, &block)
        current_const_name = visitor.current_self_type_name
        const = visitor.const_registry.find(current_const_name)

        if node.arguments.nil?
          visitor.current_method_visibility = :public
        elsif node.arguments.arguments.first.is_a?(Prism::DefNode)
          def_node = node.arguments.arguments.first

          block.call

          method_obj = visitor.method_registry.find(
            current_const_name,
            def_node.name.to_s,
            singleton: visitor.current_in_singleton,
          )
          method_obj.visibility = :public
        else
          node.arguments.arguments.each do |arg_node|
            method_obj = visitor.method_registry.find(
              current_const_name,
              arg_node.unescaped,
              singleton: visitor.current_in_singleton,
            )
            method_obj.visibility = :public
          end
        end
      end
    end
  end
end
