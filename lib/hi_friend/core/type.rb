module HiFriend::Core
  module Type
    class Base
      def to_human_s
        raise NotImplementedError
      end

      def ==(other)
        self.class == other.class && self.to_human_s == other.to_human_s
      end
    end

    class Any < Base
      def to_human_s
        "any"
      end
    end

    class Nil < Base
      def to_human_s
        "nil"
      end
    end

    class True < Base
      def to_human_s
        "true"
      end
    end

    class False < Base
      def to_human_s
        "false"
      end
    end

    class Integer < Base
      def to_human_s
        "Integer"
      end
    end

    class Union < Base
      attr_reader :element_types

      def initialize(element_types)
        super()
        @element_types = element_types
      end

      def to_human_s
        @element_types.map(&:to_human_s).join(' | ')
      end

      class << self
        def build(types)
          flatten_types = types.flat_map do |type|
            if type.is_a?(Union)
              type.element_types
            else
              [type]
            end
          end

          element_types = []
          flatten_types.each do |type|
            if !element_types.include?(type)
              element_types << type
            end
          end

          new(element_types)
        end
      end
    end

    class Array < Base
      def initialize(element_type)
        super()
        @element_type = element_type
      end

      def to_human_s
        "[#{@element_type.to_human_s}]"
      end
    end

    class Hash < Base
      def initialize(key_types, value_types)
        super
        @key_types = key_types
        @value_types = value_types
      end

      def to_human_s
        key_types = @key_types.map(&:to_human_s).join(' | ')
        value_types = @value_types.map(&:to_human_s).join(' | ')
        "{#{key_types} => #{value_types}}"
      end
    end

    class Symbol < Base
      def initialize(name)
        super()

        @name = name
      end

      def to_human_s
        ":#{@name}"
      end
    end

    class Const < Base
      def initialize(const_name)
        super()

        @const_name = const_name
      end

      def to_human_s
        @const_name
      end
    end

    module_function

    def any = (@any ||= Any.new)
    def nil = (@nil ||= Nil.new)
    def true = (@true ||= True.new)
    def false = (@false ||= False.new)
    def integer = (@integer ||= Integer.new)
    def const(name) = Const.new(name)
    def symbol(name) = Symbol.new(name)
    def array(el_type) = Array.new(el_type)

    def union(given_types)
      flatten_types = given_types.flat_map do |type|
        if type.is_a?(Union)
          type.element_types
        else
          [type]
        end
      end

      uniq_types = []
      flatten_types.each do |type|
        if !uniq_types.include?(type)
          uniq_types << type
        end
      end

      if uniq_types.size == 1
        uniq_types.first
      else
        Union.new(uniq_types)
      end
    end
  end
end
