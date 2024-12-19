module HiFriend::Core
  class ConstRegistry
    def initialize
      @const_by_name = {}
      @consts_by_path = Hash.new { |h, k| h[k] = [] }
    end

    def add(const_name, node, path)
      @const_by_name[const_name] ||= Constant.new(const_name, node)

      const = @const_by_name[const_name]
      const.add_path(path)

      @consts_by_path[path] << const
    end

    def remove_by_path(path)
      consts = @consts_by_path.delete(path)
      if consts
        consts.each do |const|
          const.remove_path(path)

          @const_by_name.delete(const.name) if const.dangling?
        end
      end

      @const_by_name.values.each do |const|
        const.remove_ivar_ref_path(path)
      end
    end

    def find(const_name)
      @const_by_name[const_name]
    end

    def lookup(scope, const_name)
      return find(const_name) if scope.empty?

      tokens = scope.split("::")
      tokens.size.downto(1) do |i|
        prefix = tokens[0, i].join("::")
        const = find("#{prefix}::#{const_name}")
        return const if const
      end
      find(const_name)
    end

    # test purpose
    def all_keys
      @const_by_name.keys
    end

    def clear
      @const_by_name.clear
      @consts_by_path.clear
    end
  end
end
