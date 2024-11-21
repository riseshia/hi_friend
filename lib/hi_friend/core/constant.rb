module HiFriend::Core
  class Constant
    attr_reader :path, :node

    def initialize(path, prism_node)
      @path = path
      @node = prism_node
      @ivar_read_tvs = Hash.new { |h, k| h[k] = [] }
    end

    def add_ivar_read_tv(ivar_read_tv)
      @ivar_read_tvs[ivar_read_tv.name] << ivar_read_tv
    end

    def ivar_type_inference(ivar_name)
      Type.nil
    end
  end
end
