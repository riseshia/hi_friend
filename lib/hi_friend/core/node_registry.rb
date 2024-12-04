module HiFriend::Core
  class NodeRegistry
    def initialize
      @objs_by_path = Hash.new { |h, k| h[k] = {} }
    end

    def add(path, obj)
      id = build_id(path, obj.node.node_id)
      @objs_by_path[path][id] = obj
    end

    def remove(path, node_id)
      id = build_id(path, node_id)
      @objs_by_path[path].delete(id)
    end

    def remove_by_path(path)
      @objs_by_path.delete(path)
    end

    def find(path, node_id)
      id = build_id(path, node_id)
      @objs_by_path[path][id]
    end

    # test purpose
    def all_keys
      @objs_by_path.values.flat_map(&:keys)
    end

    def clear
      @objs_by_path.clear
    end

    private def build_id(path, node_id)
      "#{path}:#{node_id}"
    end
  end
end
