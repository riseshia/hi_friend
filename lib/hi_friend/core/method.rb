module HiFriend::Core
  class Method
    attr_reader :id, :paths, :node, :receiver_type,
                :arg_tvs, :return_tvs, :return_type

    def initialize(id:, receiver_type:, node:)
      @id = id
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

    def name
      @node.name
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
      # XXX: more information
      name
    end
  end

  class AttrReader < Method
    def name
      @node.unescaped
    end

    def infer_arg_type(_)
      raise "AttrReader does not have arguments"
    end

    def add_arg_type(_, _)
      raise "AttrReader does not have arguments"
    end

    def add_return_type(type)
      @return_type = type
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

    def add_call_location_tv(call_tv)
      @call_location_tvs << call_tv
    end

    def hover
      # XXX: more information
      name
    end
  end
end
