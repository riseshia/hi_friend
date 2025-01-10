require "set"

module HiFriend::Core
  class MethodRegistry
    def initialize
      @method_by_id = {}
      @methods_by_path = Hash.new { |h, k| h[k] = [] }
      @methods_by_name = Hash.new { |h, k| h[k] = [] }
    end

    def add(
      receiver_name:,
      name:,
      node:,
      path:,
      singleton:,
      visibility:,
      type: :method
    )
      id = build_id(receiver_name, name, singleton: singleton)

      @method_by_id[id] ||= method_class(type).new(
        id: id,
        name: name,
        node: node,
        receiver_type: Type.const(receiver_name, singleton: singleton),
        visibility: visibility,
      )
      method = @method_by_id[id]
      method.add_path(path)

      @methods_by_path[path] << method
      @methods_by_name[name] << method

      method
    end

    private def method_class(type)
      case type
      when :method then Method
      when :attr_reader then AttrReader
      when :attr_writer then AttrWriter
      else
        raise "Unknown method type: #{type}"
      end
    end

    def remove_by_path(path)
      methods = @methods_by_path.delete(path)
      if methods
        methods.each do |method|
          method.remove_path(path)
          @method_by_id.delete(method.id) if method.dangling?
          @methods_by_name[method.name].delete_if { |m| m == method }
        end
      end

      @method_by_id.values.each do |method|
        method.remove_caller_ref_path(path)
      end
    end

    def find(const_name, method_name, visibility: nil, singleton: false)
      id = build_id(const_name, method_name, singleton: singleton)

      obj = @method_by_id[id]
      return nil if obj.nil?
      return nil if visibility && obj.visibility != visibility

      obj
    end

    def find_by_id(id)
      @method_by_id[id]
    end

    # test purpose
    def all_keys
      @method_by_id.keys
    end

    def clear
      @method_by_id.clear
      @methods_by_path.clear
      @methods_by_name.clear
    end

    def guess_receiver_type_by_methods(method_names)
      return Type.any if method_names.empty?

      sets = method_names.map do |method_name|
        Set.new(@methods_by_name[method_name].map(&:receiver_type))
      end

      candidates = sets.reduce(&:intersection)

      if candidates.size == 1
        candidates.first
      else
        if method_names.size == 1
          Type.duck(method_names.first)
        else
          Type.any
        end
      end
    end

    def guess_method(name)
      candidates = @methods_by_name[name]

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
