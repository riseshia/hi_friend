module HiFriend::Core
  module TypeVertex
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
        type_var.add_dependent(self)
      end

      protected def add_dependent(type_var)
        @dependents << type_var
      end

      def infer(constraints = {})
        raise NotImplementedError
      end

      def hover
        @inferred_type.to_ts
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

      def order(order)
        @order = order
      end

      def infer(constraints = {})
        # delegate to method_obj
        @inferred_type = @method_obj.infer_arg_type(@name, constraints)
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

    class ConstRead < Base
      def set_const(const)
        @candidates[0] = const
      end

      def infer(constraints = {})
        const = @candidates.first

        @inferred_type =
          if const.is_a?(ClassOrModule)
            Type.const(const.name, singleton: true)
          else
            const.infer(constraints)
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

    class Hash < Base
      def initialize(path:, name:, node:)
        super
        @kvs = []
      end

      def infer(constraints = {})
        kv_types = @kvs.map { |k, v| [k.infer(constraints), v.infer(constraints)] }

        @inferred_type = Type.hash(kv_types)
      end

      def add_kv(k, v)
        @kvs << [k, v]
        @dependencies << k
        @dependencies << v
        k.add_dependent(self)
        v.add_dependent(self)
      end
    end

    class InterpolatedString < Base
      def infer(constraints = {})
        @dependencies.each { _1.infer(constraints) }

        # Return always string not to breake further inference
        @inferred_type = Type.string
      end
    end

    class EmbeddedStatements < Base
      def infer(constraints = {})
        @dependencies.each { _1.infer(constraints) }

        @inferred_type = @dependencies.last.inferred_type
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
        @fast_inferred_receiver_type = Type.any
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

      # This method will be called before in earnest inference.
      # type inference with recevied method name to be done before that,
      # because most of method call receivers are not constant, but variable,
      # which is not determined its type until inference time(or never).
      def fast_infer_receiver_type
        @fast_inferred_receiver_type =
          if @receiver_tv
            receiver_type = guess_const_by_received_method(@name)

            receiver_type || Type.any
          else # receiver is self
            const = HiFriend::Core.const_registry.find(@scope)

            if const
              Type.const(const.name, singleton: false)
            else
              # XXX: Someday this case should be removed.
              #      It's a workaround for the case that builtin class.
              Type.any
            end
          end
      end

      def infer(constraints = {})
        method_name = @name

        method_visibility_scope = receiver_type_is_self? ? :private : :public
        receiver_type =
          if receiver_type_is_self?
            determine_type_of_self
          elsif @fast_inferred_receiver_type.is_a?(Type::Any)
            # if receiver type still unknown, try to infer it with slow path.
            @receiver_tv.infer({ received_methods: [method_name] })
          else
            @fast_inferred_receiver_type
          end

        @inferred_type =
          if receiver_type.is_a?(Type::Any)
            Type.any
          elsif receiver_type.is_a?(Type::Union)
            # XXX: Someday this case should be handled. such as A | B
            Type.any
          else
            method_obj = lookup_method(
              const_registry: HiFriend::Core.const_registry,
              method_registry: HiFriend::Core.method_registry,
              const_name: receiver_type.name,
              method_name: method_name,
              singleton: receiver_type.singleton?,
              visibility: method_visibility_scope,
            )
            method_obj.infer_return_type(constraints)
          end
      end

      private def receiver_type_is_self?
        @receiver_tv.nil?
      end

      private def determine_type_of_self
        const = HiFriend::Core.const_registry.find(@scope)

        if const
          Type.const(const.name, singleton: false)
        else
          # XXX: Someday this case should be removed.
          #      It's a workaround for the case that builtin class.
          Type.any
        end
      end

      private def guess_const_by_received_method(method_name)
        candidate = HiFriend::Core.method_registry.guess_method(method_name)

        candidate&.receiver_type
      end

      private def lookup_method(const_registry:, method_registry:, const_name:, method_name:, visibility:, singleton:)
        # const_obj = const_registry.find(const_name)
        method_registry.find(const_name, method_name, visibility: visibility, singleton: singleton)
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
