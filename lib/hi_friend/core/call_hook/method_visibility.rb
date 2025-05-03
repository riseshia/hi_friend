module HiFriend::Core
  module CallHook
    # public/protected/private:
    # - change the visibility of the method to target visibility
    # - set the visibility of given method to target visibility
    # - set the visibility of methods of given name to target visibility
    class MethodVisibility < Base
      TARGET_METHOD_NAMES = %w[public private protected].freeze

      def matched?(_const_name, method_name)
        TARGET_METHOD_NAMES.include?(method_name)
      end

      def call(visitor, node, &block)
        current_const_name = visitor.current_self_type_name
        const = visitor.const_registry.find(current_const_name)

        target_visibility = node.name

        if node.arguments.nil?
          # change default
          visitor.change_current_method_visibility(target_visibility)
        elsif node.arguments.arguments.first.is_a?(Prism::DefNode)
          # inline change
          def_node = node.arguments.arguments.first

          visitor.in_method_visibility(target_visibility) do
            block.call
          end

          # method_obj = visitor.method_registry.find(
          #   current_const_name,
          #   def_node.name.to_s,
          #   singleton: visitor.current_in_singleton,
          # )
          # method_obj.visibility = target_visibility
        else
          # change after def
          node.arguments.arguments.each do |arg_node|
            # Handle string or symbol only.
            receiver = Receiver.find_by_fqname(db: visitor.db, fqname: visitor.current_self_type_name_with_singleton)

            if receiver
              MethodModel.change_visibility(
                db: visitor.db,
                receiver_id: receiver.id,
                name: arg_node.unescaped,
                visibility: target_visibility
              )
            else
              # XXX: maybe add diaginostic?
            end

            if arg_node.respond_to?(:unescaped)
              # method_obj = visitor.method_registry.find(
              #   current_const_name,
              #   arg_node.unescaped,
              #   singleton: visitor.current_in_singleton,
              # )
              # method_obj.visibility = target_visibility
            else
              # Do nothing with arg node, such lvar.
            end
          end
        end
      end
    end
  end
end
