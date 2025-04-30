module HiFriend::Core
  module CallHook
    # class A
    #   include B
    # end
    class ModuleInclude < Base
      def matched?(_const_name, method_name)
        method_name == "include"
      end

      def call(visitor, node, &block)
        current_const_name = visitor.current_self_type_name

        node.arguments&.arguments&.each do |arg_node|
          names = visitor.extract_const_names(arg_node)
          included_module_name = names.join("::")

          IncludedModule.insert(
            db: visitor.db,
            kind: :mixin,
            target_fqname: current_const_name,
            eval_scope: current_const_name,
            passed_name: included_module_name,
            file_path: visitor.source.path,
            line: node.location.start_line,
          )
        end
      end
    end
  end
end
