module HiFriend::Core
  class MethodRegistry
    def initialize
      @method_by_id = {}
      @methods_by_path = Hash.new { |h, k| h[k] = [] }
    end

    def add(
      receiver_name:,
      name:,
      node:,
      path:,
      singleton:
    )
      id = build_id(receiver_name, node.name, singleton: singleton)

      @method_by_id[id] ||= Method.new(
        id: id,
        node: node,
        receiver_type: Type::Const.new(receiver_name),
      )
      method = @method_by_id[id]
      method.add_path(path)

      @methods_by_path[path] << method

      method
    end

    def remove_by_path(path)
      methods = @methods_by_path.delete(path)
      return if methods.nil?

      methods.each do |method|
        method.remove_path(path)
        @method_by_id.delete(method.id) if method.dangling?
      end
    end

    def find(const_name, method_name, visibility:, singleton: false)
      id = build_id(const_name, method_name, singleton: singleton)
      @method_by_id[id]
    end

    # test purpose
    def all_keys
      @method_by_id.keys
    end

    def clear
      @method_by_id.clear
      @methods_by_path.clear
    end

    def guess_method(name)
      candidates = @method_by_id.values.select { |v| v.name == name }

      if candidates.size == 1
        candidates.values.first
      else
        nil
      end
    end

    private def build_id(const_name, method_name, singleton:)
      middle = singleton ? "." : "#"
      "#{const_name}#{middle}#{method_name}"
    end
  end
end
