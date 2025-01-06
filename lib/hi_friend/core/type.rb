module HiFriend::Core
  module Type
    class Base
      def name
        raise NotImplementedError
      end

      def to_human_s
        raise NotImplementedError
      end

      def singleton? = false

      def ==(other)
        self.class == other.class && self.to_human_s == other.to_human_s
      end
    end

    class Void < Base
      def name = "void"
      def to_human_s = "void"
    end

    class Any < Base
      def name = "any"
      def to_human_s = "any"
    end

    class Self < Base
      def name = "self"
      def to_human_s = "self"
    end

    class Class < Base
      def name = "class"
      def to_human_s = "class"
    end

    class Instance < Base
      def name = "instance"
      def to_human_s = "instance"
    end

    class Nil < Base
      def name = "nil"
      def to_human_s = "nil"
    end

    class True < Base
      def name = "true"
      def to_human_s = "true"
    end

    class False < Base
      def name = "false"
      def to_human_s = "false"
    end

    class Bool < Base
      def name = "bool"
      def to_human_s = "bool"
    end

    class Integer < Base
      def name = "Integer"
      def to_human_s = "Integer"
    end

    class String < Base
      def initialize(literal)
        super()

        @literal = literal
      end

      def literal? = !!@literal

      def name = "String"

      def to_human_s
        if @literal
          "\"#{@literal}\""
        else
          "String"
        end
      end
    end

    class Symbol < Base
      def initialize(val)
        super()

        @val = val
      end

      def name = "Symbol"

      def to_human_s
        ":#{@val}"
      end
    end

    class Union < Base
      attr_reader :element_types

      def initialize(element_types)
        super()
        @element_types = element_types
      end

      def name = @element_types.map(&:name).join(' | ')

      def to_human_s
        @element_types.map(&:to_human_s).join(' | ')
      end
    end

    class Array < Base
      def initialize(element_type)
        super()
        @element_type = element_type
      end

      def name = "[#{@element_type.name}]"

      def to_human_s
        "[#{@element_type.to_human_s}]"
      end
    end

    class Hash < Base
      def initialize(kvs)
        super()
        @kvs = kvs
      end

      def name
        keys = @kvs.map(&:first)
        values = @kvs.map(&:last)

        key = Type.union(keys)
        value = Type.union(values)

        "{ #{key.name} => #{value.name} }"
      end

      def to_human_s
        if fixed?
          kv_hs = @kvs.map do |k, v|
            if k.is_a?(Symbol)
              "#{k.to_human_s.sub(':', '')}: #{v.to_human_s}"
            else
              "#{k.to_human_s} => #{v.to_human_s}"
            end
          end
          "{ #{kv_hs.join(', ')} }"
        else
          keys = @kvs.map(&:first)
          values = @kvs.map(&:last)

          key = Type.union(keys)
          value = Type.union(values)

          "{ #{key.to_human_s} => #{value.to_human_s} }"
        end
      end

      private def fixed?
        @kvs.map(&:first).all? { (_1.is_a?(String) && _1.literal?) || _1.is_a?(Symbol) }
      end
    end

    class Const < Base
      def initialize(const_name, singleton: false)
        super()

        @const_name = const_name
        @singleton = singleton
      end

      def name = @const_name

      def singleton? = @singleton

      def to_human_s
        if @singleton
          "singleton(#{@const_name})"
        else
          @const_name
        end
      end
    end

    module_function

    def void = (@void ||= Void.new)
    def any = (@any ||= Any.new)
    def self0 = (@self0 ||= Self.new)
    def class0 = (@class0 ||= Class.new)
    def instance = (@class0 ||= Instance.new)
    def nil = (@nil ||= Nil.new)
    def true = (@true ||= True.new)
    def false = (@false ||= False.new)
    def bool = (@bool ||= Bool.new)
    def integer = (@integer ||= Integer.new)
    def string(literal = nil) = String.new(literal)
    def const(name, singleton:) = Const.new(name, singleton: singleton)
    def symbol(name) = Symbol.new(name)
    def array(el_type) = Array.new(el_type)
    def hash(kvs) = Hash.new(kvs)

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

      return uniq_types.first if uniq_types.size == 1

      if uniq_types.size == 2 && uniq_types.include?(Type.true) && uniq_types.include?(Type.false)
        return Type.bool
      end

      Union.new(uniq_types)
    end
  end
end
