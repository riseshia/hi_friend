module HiFriend::Core
  class NodeRegistry
    def initialize
      @objs_by_path = Hash.new { |h, k| h[k] = {} }
    end

    def add(path, obj)
      @objs_by_path[path][obj.node.node_id] = obj
    end

    def remove(path, node_id)
      @objs_by_path[path].delete(node_id)
    end

    def remove_by_path(path)
      @objs_by_path.delete(path)
    end

    def find(path, node_id)
      @objs_by_path[path][node_id]
    end

    # test purpose
    def all_keys
      @objs_by_path.values.flat_map(&:keys)
    end

    def clear
      @objs_by_path.clear
    end
  end
end
