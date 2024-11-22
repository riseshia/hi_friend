module HiFriend::Core
  class ConstRegistry
    def initialize
      @registry = {}
    end

    def add(const_name, node, path)
      @registry[const_name] = Constant.new(path, node)
    end

    def remove(const_name)
      @registry.delete(const_name)
    end

    def remove_by_path(path)
      @registry.delete_if { |_, const| const.path == path }
    end

    def find(const_name)
      @registry[const_name]
    end

    def all_keys
      @registry.keys
    end

    def clear
      @registry.clear
    end
  end
end
