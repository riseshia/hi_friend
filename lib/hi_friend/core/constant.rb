module HiFriend::Core
  class Constant
    attr_reader :path, :node

    def initialize(path, prism_node)
      @path = path
      @node = prism_node
    end
  end
end
