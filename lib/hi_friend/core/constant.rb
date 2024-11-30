module HiFriend::Core
  class Constant
    attr_reader :name, :paths, :node

    def initialize(name, prism_node)
      @name = name
      @node = prism_node
      @paths = []
      @ivar_read_tvs = Hash.new { |h, k| h[k] = [] }
      @ivar_write_tvs = {}
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
end
