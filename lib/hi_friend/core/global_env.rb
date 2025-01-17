require "rbs"

require_relative "../rbs_type_converter"

module HiFriend::Core
  class GlobalEnv
    class << self
      def load!
        new.tap(&:load!)
      end
    end

    attr_reader :consts, :methods

    def initialize
      @consts = []
      @methods = []
    end

    def load!
      load_stdlib_from_rbs
    end

    private def load_stdlib_from_rbs
      loader = RBS::EnvironmentLoader.new
      environment = RBS::Environment.from_loader(loader).resolve_type_names
      @builder = RBS::DefinitionBuilder.new(env: environment)

      @consts = [] # try reset
      @methods = [] # try reset

      environment.interface_decls.each do |type_name, interface_decl|
        name = type_name.to_s.sub("::", "")
        decl = interface_decl.decl
        path = decl.location.name
        interface = Interface.new(name, path)

        decl.members.each do |rbs_method_def|
          method_defs = rbs_method_def.overloads.map do |overload|
            convert_rbs_function_type_to_method_def(overload.method_type.type, :public)
          end
        end
      end

      environment.class_decls.each do |type_name, class_decl|
        kind = environment.class_decl?(type_name) ? :class : :module
        const = convert_rbs_class_decl_to_const(kind, class_decl)
        @consts << const

        singleton_def = @builder.build_singleton(type_name)
        singleton_def.methods.each do |method_name, rbs_method_def|
          accessiblity = rbs_method_def.accessibility
          rbs_method_def.defs.each do |rbs_method_tdef|
            method_def = convert_rbs_function_type_to_method_def(rbs_method_tdef.type.type, accessiblity)
            # @methods << method_def
          end
        end

        instance_def = @builder.build_instance(type_name)
        instance_def.methods.each do |method_name, rbs_method_def|
          accessiblity = rbs_method_def.accessibility
          rbs_method_def.defs.each do |rbs_method_tdef|
            method_def = convert_rbs_function_type_to_method_def(rbs_method_tdef.type.type, accessiblity)
            # @methods << method_def
          end
        end
      end

      environment.constant_decls.each do |type_name, constant_decl|
        const = convert_rbs_constant_decl_to_const(constant_decl)
        @consts << const

        type = convert_rbs_type_to_our_type(constant_decl.decl.type)
        const.set_value_type(type)
      end
    end

    private def convert_rbs_class_decl_to_const(kind, class_decl)
      type_name = class_decl.name
      const_name = type_name.to_s.sub("::", "")
      paths = class_decl.decls.flat_map { |d| d.decl.annotations.map { |at| at.location.name } }

      const = ClassOrModule.new(const_name, nil, kind: kind, external: true)
      paths.each { |path| const.add_path(path) }

      const
    end

    private def convert_rbs_constant_decl_to_const(constant_decl)
      type_name = constant_decl.name
      const_name = type_name.to_s.sub("::", "")
      path = constant_decl.decl.location.name

      const = ConstVariable.new(const_name, nil, external: true)
      const.add_path(path)

      const
    end

    private def convert_rbs_function_type_to_method_def(function_type, visibility)
      if function_type.is_a?(RBS::Types::UntypedFunction)
        return AnyFunction.new.tap do |md|
          md.visibility = visibility
          md.return_type = convert_rbs_type_to_our_type(function_type.return_type)
        end
      end

      MethodDefinition.new.tap do |md|
        md.visibility = visibility
        md.return_type = convert_rbs_type_to_our_type(function_type.return_type)

        function_type.required_positionals.each do |type|
          md.required_positionals[type.name] = convert_rbs_type_to_our_type(type.type)
        end
        function_type.optional_positionals.each do |type|
          md.optional_positionals[type.name] = convert_rbs_type_to_our_type(type.type)
        end
        function_type.required_keywords.each do |name, type|
          md.required_keywords[name] = convert_rbs_type_to_our_type(type.type)
        end
        function_type.optional_keywords.each do |name, type|
          md.optional_keywords[name] = convert_rbs_type_to_our_type(type.type)
        end

        if function_type.rest_positionals
          md.rest_positionals[function_type.rest_positionals.name] = convert_rbs_type_to_our_type(function_type.rest_positionals.type)
        end
        if function_type.rest_keywords
          md.rest_keywords[function_type.rest_keywords.name] = convert_rbs_type_to_our_type(function_type.rest_keywords.type)
        end
      end
    end

    private def convert_rbs_type_to_our_type(type)
      HiFriend::RbsTypeConverter.convert(@builder, type)
    end
  end
end
