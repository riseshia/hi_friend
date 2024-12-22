module HiFriend::Core
  class MethodBase
    attr_reader :id, :paths, :name, :node, :receiver_type,
                :arg_tvs, :return_tvs, :return_type

    def initialize(id:, name:, receiver_type:, node:)
      @id = id
      @name = name
      @paths = []
      @node = node
      @receiver_type = receiver_type

      @arg_types = {}
      @return_type = nil

      @arg_tvs = {}
      @return_tvs = []
      @call_location_tvs = []
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

    def infer_return_type
      raise NotImplementedError
    end

    def add_arg_type(name, type)
      @arg_types[name] = type
    end

    def add_return_type(type)
      @return_type = type
    end

    def add_arg_tv(arg_tv)
      @arg_tvs[arg_tv.name] = arg_tv
      arg_tv.add_method_obj(self)
    end

    def add_return_tv(return_tv)
      @return_tvs << return_tv
    end

    def add_call_location_tv(call_tv)
      @call_location_tvs << call_tv
    end

    def hover
      raise NotImplementedError
    end
  end

  class Method < MethodBase
    attr_reader :id, :paths, :node, :receiver_type,
                :arg_tvs, :return_tvs, :return_type

    def infer_arg_type(name)
      if @arg_types.key?(name)
        @arg_types[name]
      elsif @arg_tvs[name].dependencies.size > 0
        # has default value
        Type.union(@arg_tvs[name].dependencies.map(&:infer))
      else
        Type.any
      end
    end

    def infer_return_type
      if @return_type
        @return_type
      else
        # XXX: Try some guess with @return_tvs
        Type.any
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

    def add_arg_type(_, _)
      raise "AttrReader does not have arguments"
    end

    def receiver_obj(const)
      @receiver_obj = const
    end

    def infer_return_type
      ivar_name = "@#{name}"
      @receiver_obj.ivar_type_infer(ivar_name, {})
    end

    def add_arg_tv(arg_tv)
      raise "AttrReader does not have arguments"
    end

    def add_return_tv(return_tv)
      raise "AttrReader can't be added return tv"
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

    def add_arg_type(_, _)
      # XXX: TBW
      raise "AttrWriter does not accept argument type"
    end

    def receiver_obj(const)
      @receiver_obj = const
    end

    def infer_return_type
      guess_ivar_type
    end

    def add_arg_tv(arg_tv)
      raise "AttrWriter does not accept argument tv"
    end

    def add_return_tv(return_tv)
      raise "AttrWriter does not accept return tv"
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
