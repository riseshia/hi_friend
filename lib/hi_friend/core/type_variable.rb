module HiFriend::Core
  module TypeVariable
    class Base
      attr_reader :node, :path, :stable,
                  :candidates, :dependencies, :dependents,
                  :inferred_type
      attr_accessor :name

      def initialize(path:, name:, node:)
        @path = path
        @name = name
        @node = node

        @candidates = []
        @dependencies = []
        @dependents = []
        @inferred_type = Type.any
      end

      def leaf? = @dependents.empty?

      def id
        @id ||= @node.node_id
      end

      def add_dependency(type_var)
        @dependencies << type_var
      end

      def add_dependent(type_var)
        @dependents << type_var
      end

      def infer(constraints = {})
        raise NotImplementedError
      end

      def hover
        @inferred_type.to_human_s
      end

      def guess_const_by_received_methods(method_names)
        candidates = method_names.map do |method_name|
          HiFriend::Core.method_registry.guess_method(method_name)
        end
        candidates.compact!.uniq!

        return nil if candidates.size != 1

        method = candidates.first
        method.receiver_type
      end
    end

    class Arg < Base
      attr_reader :method_obj

      def initialize(path:, name:, node:)
        super
        @method_obj = nil
      end

      def add_method_obj(method_obj)
        @method_obj = method_obj
      end

      def infer(constraints = {})
        # delegate to method_obj
        @inferred_type = @method_obj.infer_arg_type(@name)
      end
    end

    class LvarWrite < Base
      def infer(constraints = {})
        @inferred_type = @dependencies[0].infer(constraints)
      end
    end

    class LvarRead < Base
      def infer(constraints = {})
        guessed_type = Type.any
        if constraints[:received_methods]
          guessed_type = guess_const_by_received_methods(constraints[:received_methods])
        end

        accurate_type = @dependencies[0].infer(constraints)
        @inferred_type =
          if accurate_type.is_a?(Type::Any)
            guessed_type
          else
            accurate_type
          end
      end
    end

    class IvarWrite < Base
      def receiver(const)
        @const = const
      end

      def infer(constraints = {})
        @inferred_type = @dependencies[0].infer(constraints)
      end
    end

    class IvarRead < Base
      def receiver(const)
        @const = const
      end

      def infer(constraints = {})
        guessed_type = Type.any
        if constraints[:received_methods]
          guessed_type = guess_const_by_received_methods(constraints[:received_methods])
        end

        accurate_type = @const.ivar_type_infer(@name, constraints)
        @inferred_type =
          if accurate_type.is_a?(Type::Any)
            guessed_type
          else
            accurate_type
          end
      end
    end

    class Array < Base
      def infer(constraints = {})
        el_types = @dependencies.map { _1.infer(constraints) }
        el_type = Type.union(el_types)
        @inferred_type = Type.array(el_type)
      end
    end

    class Static < Base
      def correct_type(type)
        @candidates[0] = type
      end

      def infer(constraints = {})
        @inferred_type = @candidates.first
      end
    end

    class Break < Base
      def infer(constraints = {})
        @inferred_type =
          if @dependencies.empty?
            Type.nil
          else
            el_types = @dependencies.map { _1.infer(constraints) }
            Type.union(el_types)
          end
      end
    end

    class Call < Base
      attr_reader :receiver_tv, :args, :scope

      def initialize(path:, name:, node:)
        super
        @receiver_tv = nil
        @args = []
      end

      def add_receiver_tv(receiver_tv)
        @receiver_tv = receiver_tv
        @dependencies << receiver_tv
        receiver_tv.add_dependent(self)
      end

      def add_arg_tv(arg)
        @args << arg
        @dependencies << arg
        arg.add_dependent(self)
      end

      def add_scope(const_name)
        @scope = const_name
      end

      def infer(constraints = {})
        method_name = @name

        receiver_type = @receiver_tv.infer({ received_methods: [method_name] })

        @inferred_type =
          if receiver_type.is_a?(Type::Any)
            Type.any
          else
            method_obj = HiFriend::Core.method_registry.find(receiver_type.to_human_s, @name, visibility: :public)
            method_obj.infer_return_type
          end
      end
    end

    class If < Base
      attr_reader :predicate

      def initialize(path:, name:, node:)
        super
        @predicate = nil
      end

      def add_predicate(predicate)
        @predicate = predicate
        predicate.add_dependent(self)
      end

      def infer(constraints = {})
        types = @dependencies.map { _1.infer(constraints) }
        if types.size == 1 # if cond without else
          types.push(Type.nil)
        end

        @inferred_type = Type.union(types)
      end
    end
  end
end
