module HiFriend::Core
  module CallHook
    # module A
    #   module_function
    # end
    class ModuleFunction < Base
      def matched?(_const_name, method_name)
        method_name == "module_function"
      end

      def call(visitor, node, &block)
        current_const_name = visitor.current_self_type_name

        if node.arguments.nil?
          visitor.mark_as_module_function
        else
          node.arguments.arguments.each do |arg_node|
            next if !arg_node.respond_to?(:unescaped)

            scope_name = visitor.current_self_type_name_with_singleton
            receiver = Receiver.find_by_fqname(db: visitor.db, fqname: scope_name)
            next if receiver.nil?

            singleton_of_receiver = Receiver.find_by_fqname(db: visitor.db, fqname: "singleton(#{scope_name})")
            methods = MethodModel.where(db: visitor.db, receiver_id: receiver.id, name: arg_node.unescaped)

            methods.each do |method|
              MethodModel.change_visibility(
                db: visitor.db,
                receiver_id: receiver.id,
                name: method.name,
                visibility: :private
              )
              MethodModel.insert(
                db: visitor.db,
                receiver_id: singleton_of_receiver.id,
                visibility: :public,
                name: method.name,
                file_path: method.file_path,
                line: method.line,
              )
            end
          end
        end
      end
    end
  end
end
