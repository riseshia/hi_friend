module HiFriend::Core
  class ClassOrModule
    attr_reader :name, :paths, :node, :kind

    def initialize(name, prism_node, kind:, external: false)
      @name = name
      @node = prism_node
      @paths = []
      @ivar_read_tvs = Hash.new { |h, k| h[k] = [] }
      @ivar_write_tvs = {}
      @kind = kind
      @external = external
      @superclass_scope = ""
      @superclass_name = "Object"
      @superclass_declared_paths = []
    end

    def add_superclass(scope, name, path)
      @superclass_scope = scope
      @superclass_name = name
      @superclass_declared_paths << path
    end

    def superclass
      HiFriend::Core.const_registry.lookup(@superclass_scope, @superclass_name)
    end

    def add_path(path)
      @paths << path
    end

    def remove_path(given_path)
      @paths.delete_if { |path| path == given_path }

      @superclass_declared_paths.delete_if { |path| path == given_path }
      reset_superclass if @superclass_declared_paths.empty?
    end

    private def reset_superclass
      @superclass_scope = ""
      @superclass_name = "Object"
    end

    def remove_ivar_ref_path(given_path)
      @ivar_read_tvs.delete_if { |path| path == given_path }
      @ivar_write_tvs.delete_if { |path| path == given_path }
    end

    def dangling?
      @paths.empty?
    end

    def external?
      @external
    end

    def add_ivar_read_tv(ivar_read_tv)
      @ivar_read_tvs[ivar_read_tv.name] << ivar_read_tv
    end

    def add_ivar_write_tv(ivar_write_tv)
      @ivar_write_tvs[ivar_write_tv.name] = ivar_write_tv
    end

    def ivar_type_infer(ivar_name, constraints)
      @ivar_write_tvs[ivar_name]&.infer(constraints) || Type.nil
    end

    def hover
      raise NotImplementedError
    end
  end

  class ConstVariable
    attr_reader :name, :paths, :node

    def initialize(name, prism_node, external: false)
      @name = name
      @node = prism_node
      @value_tv = nil
      @value_type = nil
      @external = external
      @paths = []
    end

    def add_path(path)
      @paths << path
    end

    def remove_path(given_path)
      @paths.delete_if { |path| path == given_path }
    end

    def dangling?
      @paths.empty?
    end

    def external?
      @external
    end

    def hover
      raise NotImplementedError
    end

    def set_value_type(value_type)
      @value_type = value_type
    end

    def set_value_tv(value_tv)
      @value_tv = value_tv
    end

    def infer(constraints = {})
      return @value_type if @value_type

      if @value_tv.nil?
        raise "Value TV should be set before infer"
      end
      @value_tv.infer(constraints)
    end
  end
end
