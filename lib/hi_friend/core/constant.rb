module HiFriend::Core
  class Constant
    attr_reader :path, :node

    def initialize(path, prism_node)
      @path = path
      @node = prism_node
      @ivar_read_tvs = Hash.new { |h, k| h[k] = [] }
      @ivar_write_tvs = {}
    end

    def add_ivar_read_tv(ivar_read_tv)
      @ivar_read_tvs[ivar_read_tv.name] << ivar_read_tv
    end

    def add_ivar_write_tv(ivar_write_tv)
      @ivar_write_tvs[ivar_write_tv.name] = ivar_write_tv
    end

    def ivar_type_inference(ivar_name, constraints)
      @ivar_write_tvs[ivar_name]&.inference(constraints) || Type.nil
    end
  end
end
