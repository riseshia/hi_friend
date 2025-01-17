module HiFriend::Core
  class InterfaceRegistry
    def initialize
      @interface_by_name = {}
      @interfaces_by_path = Hash.new { |h, k| h[k] = [] }
    end

    def add(interface)
      @interface_by_name[interface.name] ||= interface
      @interfaces_by_path[interface.path] << interface

      interface
    end

    def remove_by_path(path)
      interfaces = @interfaces_by_path.delete(path)

      if interfaces
        interfaces.each do |interface|
          interface.remove_path(path)

          @interface_by_name.delete(interface.name)
        end
      end
    end

    def find(interface_name)
      @interface_by_name[interface_name]
    end

    # test purpose
    def all_names
      @interface_by_name.keys
    end

    def clear
      @interface_by_name.clear
      @interfaces_by_path.clear
    end
  end
end
