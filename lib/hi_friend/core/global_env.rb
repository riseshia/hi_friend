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
      builder = RBS::DefinitionBuilder.new(env: environment)

      @consts = [] # try reset
      @methods = [] # try reset

      environment.class_decls.each do |type_name, class_decl|
        kind = environment.class_decl?(type_name) ? :class : :module
        const = convert_rbs_class_decl_to_const(kind, class_decl)
        @consts << const

        singleton_def = builder.build_singleton(type_name)
        singleton_def.methods.each do |method_name, method_def|
          method_def.defs.each do |method_tdef|
            method = convert_rbs_method_to_method(const, method_tdef)
            @methods << method
          end
        end

        instance_def = builder.build_instance(type_name)
        instance_def.methods.each do |method_name, method_def|
          method_def.defs.each do |method_tdef|
            method = convert_rbs_method_to_method(const, method_tdef)
            @methods << method
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

    private def convert_rbs_method_to_method(const, method_tdef)
      method_sig = method_tdef.type.type

      required_positionals = method_sig.required_positionals
      optional_positionals = method_sig.optional_positionals
      required_keywords = method_sig.required_keywords
      optional_keywords = method_sig.optional_keywords
      rest_keywords = method_sig.rest_keywords
      rest_positionals = method_sig.rest_positionals

      # XXX: to be implemented
    end

    private def convert_rbs_type_to_our_type(type)
      HiFriend::RbsTypeConverter.convert(type)
    end
  end
end
