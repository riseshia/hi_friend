require "rbs"

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
        singleton_def.methods.each do |method_def|
          method = convert_rbs_method_to_method(const, method_def)
          @methods << method
        end

        instance_def = builder.build_instance(type_name)
        instance_def.methods.each do |method_def|
          method = convert_rbs_method_to_method(const, method_def)
          @methods << method
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

    private def convert_rbs_method_to_method(const, method_def)
      # XXX: to be implemented
    end

    private def convert_rbs_type_to_our_type(type)
      name = type.to_s.sub("::", "")
      Type.const(name, singleton: false)
    end
  end
end
