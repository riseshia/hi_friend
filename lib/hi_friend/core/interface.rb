module HiFriend::Core
  class Interface
    attr_reader :name, :path, :method_defs

    def initialize(name, path)
      @name = name
      @path = nil
      @method_defs = Hash.new { |h, k| h[k] = [] }
    end

    def add_method_def(name, method_def)
      @method_defs[name] << method_def
    end
  end
end
