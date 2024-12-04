module HiFriend::Core
  class TypeVariableRegistry
    def initialize
      @tv_by_id = {}
      @tvs_by_path = Hash.new { |h, k| h[k] = [] }
    end

    def add(var)
      id = build_id(var.path, var.id)
      @tv_by_id[id] = var
      @tvs_by_path[var.path] << var
    end

    def remove_by_path(path)
      tvs = @tvs_by_path.delete(path)

      if tvs
        tvs.each do |tv|
          id = build_id(tv.path, tv.id)
          @tv_by_id.delete(id)
        end
      end
    end

    def find(path, node_id)
      id = build_id(path, node_id)
      @tv_by_id[id]
    end

    def find_by_path(path)
      @tvs_by_path[path]
    end

    # test purpose
    def all_keys
      @tv_by_id.keys
    end

    def all
      @tv_by_id.values
    end

    def clear
      @tv_by_id.clear
    end

    private def build_id(path, node_id)
      "#{path}:#{node_id}"
    end
  end
end
