module HiFriend::Core
  class MethodBase
    attr_reader :id, :paths, :name, :node, :receiver_type,
                :arg_tvs, :return_tvs, :return_type,
                :definition

    attr_accessor :visibility

    def initialize(name:, receiver_type:, node:, visibility:)
      @name = name
      @paths = []
      @node = node
      @receiver_type = receiver_type
      @visibility = visibility

      @definition = nil

      @arg_tvs = []
      @return_tvs = []
      @call_location_tvs = []

      @id = build_id
    end

    def node_id = (@node_id ||= @node.node_id)

    def add_path(path)
      @paths << path
    end

    def remove_path(given_path)
      @paths.delete_if { |path| path == given_path }
    end

    def remove_caller_ref_path(given_path)
      @call_location_tvs.delete_if { |path| path == given_path }
    end

    def dangling?
      @paths.empty?
    end

    def infer_arg_type(name)
      raise NotImplementedError
    end

    def infer_return_type(_constraints = {})
      raise NotImplementedError
    end

    def add_call_location_tv(call_tv)
      @call_location_tvs << call_tv
    end

    def hover
      raise NotImplementedError
    end

    private def build_id
      const_name = @receiver_type.name
      middle = @receiver_type.singleton? ? "." : "#"
      "#{const_name}#{middle}#{@name}"
    end
  end

  class Method < MethodBase
    attr_reader :id, :paths, :node, :receiver_type,
                :arg_tvs, :return_tvs, :return_type

    def initialize(name:, receiver_type:, node:, visibility:)
      super
      @kwarg_tvs = {}
    end

    def add_arg_tv(arg_tv)
      @arg_tvs << arg_tv
      arg_tv.add_method_obj(self)
      arg_tv.order(@arg_tvs.size - 1)
    end

    def add_kwarg_tv(kwarg_tv)
      @kwarg_tvs[kwarg_tv.name] = kwarg_tv
      kwarg_tv.add_method_obj(self)
    end

    def add_return_tv(return_tv)
      @return_tvs << return_tv
    end

    def infer_arg_type(order, constraints = {})
      # XXX: use type declaration if exists

      arg_tv = @arg_tvs[order]

      # use inferred type if default value type could be inferred
      inferred_types_by_default_value = arg_tv.dependencies.map(&:infer)
      if inferred_types_by_default_value.size > 0
        inferred_type_by_default_value = Type.union(inferred_types_by_default_value)
        if !inferred_type_by_default_value.is_a?(Type::Any)
          return inferred_type_by_default_value
        end
      end

      # use inferred type from constraints
      received_methods = constraints.fetch(:received_methods, [])
      inferred_type_by_received_methods = guess_type_by_received_methods(received_methods)
      if !inferred_type_by_received_methods.is_a?(Type::Any)
        return inferred_type_by_received_methods
      end

      # try to infer from arguments from call location
      # XXX: TBW
      Type.any
    end

    def infer_kwarg_type(name, constraints = {})
      # XXX: use type declaration if exists

      kwarg_tv = @kwarg_tvs[name]

      # use inferred type if default value type could be inferred
      inferred_types_by_default_value = kwarg_tv.dependencies.map(&:infer)
      if inferred_types_by_default_value.size > 0
        inferred_type_by_default_value = Type.union(inferred_types_by_default_value)
        if !inferred_type_by_default_value.is_a?(Type::Any)
          return inferred_type_by_default_value
        end
      end

      # use inferred type from constraints
      received_methods = constraints.fetch(:received_methods, [])
      inferred_type_by_received_methods = guess_type_by_received_methods(received_methods)
      if !inferred_type_by_received_methods.is_a?(Type::Any)
        return inferred_type_by_received_methods
      end

      # try to infer from arguments from call location
      # XXX: TBW
      Type.any
    end

    private def guess_type_by_received_methods(method_names)
      HiFriend::Core.method_registry.guess_receiver_type_by_methods(method_names)
    end

    def infer_return_type(constraints = {})
      # XXX: use type declaration if exists
      if @return_type
        @return_type
      else
        types = @return_tvs.map { |tv| tv.infer(constraints) }
        Type.union(types)
      end
    end

    def hover
      # XXX: more information
      name
    end
  end

  class AttrReader < MethodBase
    def infer_arg_type(_)
      raise "AttrReader does not have arguments"
    end

    def receiver_obj(const)
      @receiver_obj = const
    end

    def infer_return_type(constraints = {})
      ivar_name = "@#{name}"
      @receiver_obj.ivar_type_infer(ivar_name, constraints)
    end

    def hover
      # XXX: more information
      name
    end
  end

  class AttrWriter < MethodBase
    def infer_arg_type(_)
      guess_ivar_type
    end

    def receiver_obj(const)
      @receiver_obj = const
    end

    def infer_return_type(constraints = {})
      guess_ivar_type
    end

    def hover
      # XXX: more information
      name
    end

    private def guess_ivar_type
      if @call_location_tvs.empty?
        Type.nil
      else
        Type.union(@call_location_tvs.map(&:infer))
      end
    end
  end
end
