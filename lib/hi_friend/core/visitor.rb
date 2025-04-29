# frozen_string_literal: true

module HiFriend::Core
  class Visitor < Prism::Visitor
    attr_reader :const_registry, :method_registry, :type_vertex_registry, :node_registry,
                :source, :current_in_singleton, :db

    def initialize(
      db:,
      const_registry:,
      method_registry:,
      type_vertex_registry:,
      node_registry:,
      source:
    )
      super()

      @db = db
      @const_registry = const_registry
      @method_registry = method_registry
      @type_vertex_registry = type_vertex_registry
      @node_registry = node_registry

      @source = source
      @current_scope = ["Object"]
      @lvars = []
      @current_in_singleton = false
      @current_method_name = nil
      @current_method_obj = nil
      @current_method_visibility_stack = [:private] # main start with private
      @current_if_cond_tv = nil
      @module_function_flag = false
      @last_evaluated_tv_stack = []
    end

    def visit_module_node(node)
      const_names = extract_const_names(node.constant_path)
      qualified_const_name = build_qualified_const_name(const_names)
      @const_registry.create(qualified_const_name, node, @source.path, kind: :module)

      Receiver.insert_module(
        db: @db,
        fqname: qualified_const_name,
        file_path: @source.path,
        line: node.location.start_line,
        file_hash: @source.hash,
      )

      in_scope(const_names) do
        prev_module_function_flag = @module_function_flag
        super
        @module_function_flag = prev_module_function_flag
      end
    end

    def visit_class_node(node)
      const_names = extract_const_names(node.constant_path)
      qualified_const_name = build_qualified_const_name(const_names)

      klass = @const_registry.create(
        qualified_const_name,
        node,
        @source.path,
        kind: :class,
      )

      receiver = Receiver.insert_class(
        db: @db,
        fqname: qualified_const_name,
        file_path: @source.path,
        line: node.location.start_line,
        file_hash: @source.hash,
      )

      if node.superclass
        superclass_name = extract_const_names(node.superclass).join("::")
        klass.add_superclass(
          self.current_self_type_name,
          superclass_name,
          @source.path,
        )

        IncludedModule.insert_inherit(
          db: @db,
          target_fqname: qualified_const_name,
          passed_name: superclass_name,
          file_path: @source.path,
          line: node.location.start_line,
        )
      end

      in_scope(const_names) do
        super
      end
    end

    def visit_singleton_class_node(node)
      in_singleton do
        super
      end
    end

    def visit_def_node(node)
      singleton = node.receiver.is_a?(Prism::SelfNode) || @current_in_singleton

      receiver = Receiver.find_by_fqname(@db, current_self_type_name_with_singleton)
      if receiver.nil?
        raise "Unreachable: #{receiver.fqname} on #{@source.path} at line #{node.location.start_line}"
      end

      MethodModel.insert(
        db: @db,
        receiver_id: receiver.id,
        visibility: current_method_visibility,
        name: node.name,
        file_path: @source.path,
        line: node.location.start_line,
      )

      if @module_function_flag && !receiver.is_singleton
        module_receiver = Receiver.find_by_fqname(@db, receiver.singleton_fqname)

        MethodModel.insert(
          db: @db,
          receiver_id: module_receiver.id,
          visibility: :public,
          name: node.name,
          file_path: @source.path,
          line: node.location.start_line,
        )
      end

      method_obj = @method_registry.create(
        receiver_name: current_self_type_name,
        name: node.name,
        node: node,
        path: @source.path,
        singleton: singleton,
        visibility: current_method_visibility,
      )
      @node_registry.add(@source.path, method_obj)

      in_method(node.name, method_obj) do
        super
      end
    end

    def visit_required_parameter_node(node)
      arg_tv = find_or_create_tv(node)
      @current_method_obj.add_arg_tv(arg_tv)

      super

      @lvars.push(arg_tv)
    end

    def visit_optional_parameter_node(node)
      tv = find_or_create_tv(node)
      @current_method_obj.add_arg_tv(tv)

      value_tv = find_or_create_tv(node.value)
      tv.add_dependency(value_tv)

      super

      @lvars.push(tv)
    end

    def visit_required_keyword_parameter_node(node)
      kwarg_tv = find_or_create_tv(node)
      @current_method_obj.add_kwarg_tv(kwarg_tv)

      super

      @lvars.push(kwarg_tv)
    end

    def visit_optional_keyword_parameter_node(node)
      kwarg_tv = find_or_create_tv(node)
      @current_method_obj.add_kwarg_tv(kwarg_tv)

      value_tv = find_or_create_tv(node.value)
      kwarg_tv.add_dependency(value_tv)

      super

      @lvars.push(kwarg_tv)
    end

    def visit_return_node(node)
      if node.arguments.nil?
        # means return nil, so mimic it
        tv = TypeVertex::Static.new(
          path: @source.path,
          name: "Prism::NilNode",
          node: node,
        )
        @type_vertex_registry.add(tv)
        @node_registry.add(@source.path, tv)
      else
        node.arguments.arguments.each do |arg|
          arg_tv = find_or_create_tv(arg)
          @return_tvs.push(arg_tv)
        end
      end

      super
    end

    def visit_constant_write_node(node)
      # we need this some day
      qualified_const_name = build_qualified_const_name([node.name])
      @const_registry.create(qualified_const_name, node, @source.path, kind: :var)

      super
    end

    def visit_constant_read_node(node)
      scope_name = build_qualified_const_name([])
      const = @const_registry.lookup(scope_name, node.name.to_s)

      if const.nil?
        # XXX: Someday this case make diagnostic
        raise "undefined constant: #{node.name} on scope #{scope_name}. It should be defined somewhere before."
      end

      # create tv without class/module def
      if const.is_a?(ConstVariable) || const.node.constant_path != node
        const_tv = find_or_create_tv(node)
        const_tv.set_const(const)
      end

      super

      @last_evaluated_tv = const_tv
    end

    def visit_constant_path_node(node)
      const_names = []
      idx = node
      loop do
        const_names.unshift(idx.name)
        if idx.is_a?(Prism::ConstantPathNode) && idx.parent
          idx = idx.parent
        else
          break
        end
      end
      absolute_path = idx.is_a?(Prism::ConstantPathNode)

      scope_name = absolute_path ? "" : build_qualified_const_name([])
      const_name = const_names.join("::")
      const = @const_registry.lookup(scope_name, const_name)

      if const.nil?
        const = @const_registry.create(scope_name, node, @source.path, kind: :unknown)
      end

      if const.is_a?(ConstVariable) || const.node.constant_path != node
        const_tv = find_or_create_tv(node)
        const_tv.name = const.name
        const_tv.set_const(const)
      end

      # Skip visit children to ignore it's sub constant read node

      @last_evaluated_tv = const_tv
    end

    def visit_local_variable_read_node(node)
      lvar_node = node
      lvar_read_tv = find_or_create_tv(lvar_node)

      lvar_decl_tv = find_latest_lvar_tv(lvar_read_tv.name)
      if lvar_decl_tv
        lvar_read_tv.add_dependency(lvar_decl_tv)
      else
        raise "undefined local variable: #{lvar_node.name}. It should be defined somewhere before."
      end

      super

      @last_evaluated_tv = lvar_read_tv
    end

    def visit_local_variable_write_node(node)
      lvar_node = node
      lvar_tv = find_or_create_tv(lvar_node)

      value_node = node.value
      value_tv = find_or_create_tv(value_node)

      lvar_tv.add_dependency(value_tv)

      super

      @lvars.push(lvar_tv)
      @last_evaluated_tv = lvar_tv
    end

    def visit_instance_variable_read_node(node)
      ivar_read_tv = find_or_create_tv(node)

      const = @const_registry.find(current_self_type_name)
      const.add_ivar_read_tv(ivar_read_tv)
      ivar_read_tv.receiver(const)

      super

      @last_evaluated_tv = ivar_read_tv
    end

    def visit_instance_variable_write_node(node)
      ivar_write_tv = find_or_create_tv(node)

      value_node = node.value
      value_tv = find_or_create_tv(value_node)

      ivar_write_tv.add_dependency(value_tv)

      const = @const_registry.find(current_self_type_name)
      const.add_ivar_write_tv(ivar_write_tv)
      ivar_write_tv.receiver(const)

      super

      @last_evaluated_tv = ivar_write_tv
    end

    def visit_multi_write_node(node)
      left_tvs = node.lefts.map do |left_node|
        find_or_create_tv(left_node)
      end

      value_node = node.value
      value_tv = find_or_create_tv(value_node)

      if value_node.is_a?(Prism::ArrayNode)
        element_tvs = value_node.elements.map do |element_node|
          find_or_create_tv(element_node)
        end

        if left_tvs.size == element_tvs.size
          left_tvs.zip(element_tvs).each do |left_tv, element_tv|
            left_tv.add_dependency(element_tv)
          end
        else
          # XXX todo
        end
      end

      super

      left_tvs.each do |left_tv|
        @lvars.push(left_tv)
      end
      @last_evaluated_tv = value_tv
    end

    def visit_if_node(node)
      if_cond_tv = find_or_create_tv(node)
      predicate_tv = find_or_create_tv(node.predicate)
      if_cond_tv.add_predicate(predicate_tv)

      in_if_cond(if_cond_tv) do
        super
      end
      @last_evaluated_tv = if_cond_tv
    end

    def visit_break_node(node)
      break_tv = find_or_create_tv(node)

      node.arguments&.arguments&.each do |arg_node|
        arg_tv = find_or_create_tv(arg_node)
        break_tv.add_dependency(arg_tv)
      end

      @last_evaluated_tv = break_tv
    end

    def visit_statements_node(node)
      @last_evaluated_tv_stack.push(@last_evaluated_tv)
      @last_evaluated_tv = nil

      super

      if in_if_cond?
        @current_if_cond_tv.add_dependency(@last_evaluated_tv)
      else
        if in_method?
          @return_tvs.push(@last_evaluated_tv)
        end
      end

      @last_evaluated_tv = @last_evaluated_tv_stack.pop
    end

    def visit_call_node(node)
      current_const_name = current_self_type_name
      method_name = node.name.to_s

      hook = HiFriend::Core::CallHook.fetch_matched_hook(current_const_name, method_name)
      hook.call(self, node) do
        super
      end
    end

    def visit_array_node(node)
      arr_tv = find_or_create_tv(node)

      node.elements.each do |element_node|
        element_tv = find_or_create_tv(element_node)
        arr_tv.add_dependency(element_tv)
      end

      super

      @last_evaluated_tv = arr_tv
    end

    def visit_hash_node(node)
      hash_tv = find_or_create_tv(node)

      node.elements.each do |assoc|
        key_tv = find_or_create_tv(assoc.key)
        value_tv = find_or_create_tv(assoc.value)

        hash_tv.add_kv(key_tv, value_tv)
      end

      super

      @last_evaluated_tv = hash_tv
    end

    def visit_string_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type.string(node.unescaped))

      super

      @last_evaluated_tv = value_tv
    end

    def visit_interpoled_string_node(node)
      value_tv = find_or_create_tv(node)

      node.parts.each do |part_node|
        part_tv = find_or_create_tv(part_node)
        value_tv.add_dependency(part_tv)
      end

      super

      @last_evaluated_tv = value_tv
    end

    def visit_embedded_statements_node(node)
      value_tv = find_or_create_tv(node)

      node.statements.body.each do |body_node|
        body_tv = find_or_create_tv(body_node)
        value_tv.add_dependency(body_tv)
      end

      super

      @last_evaluated_tv = value_tv
    end

    def visit_integer_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type.integer)

      super

      @last_evaluated_tv = value_tv
    end

    def visit_symbol_node(node)
      tv = find_or_create_tv(node)
      tv.correct_type(Type.symbol(tv.name))

      super

      @last_evaluated_tv = tv
    end

    def visit_true_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type.true)

      super

      @last_evaluated_tv = value_tv
    end

    def visit_false_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type.false)

      super

      @last_evaluated_tv = value_tv
    end

    def visit_nil_node(node)
      value_tv = find_or_create_tv(node)
      value_tv.correct_type(Type.nil)

      super

      @last_evaluated_tv = value_tv
    end

    def extract_const_names(const_read_node_or_const_path_node)
      if const_read_node_or_const_path_node.is_a?(Prism::ConstantReadNode)
        [const_read_node_or_const_path_node.name]
      else
        list = [const_read_node_or_const_path_node.name]

        node = const_read_node_or_const_path_node.parent
        loop do
          list.push node.name

          break if node.is_a?(Prism::ConstantReadNode)

          node = node.parent
        end

        list.reverse
      end
    end

    def current_self_type_name
      if @current_scope.size == 1
        @current_scope[0]
      else
        @current_scope[1..].map(&:to_s).join("::")
      end
    end

    def current_self_type_name_with_singleton
      return @current_scope[0] if @current_scope.size == 1

      type_name = @current_scope[1..].map(&:to_s).join("::")

      if @current_in_singleton
        "singleton(#{type_name})"
      else
        type_name
      end
    end

    def in_singleton
      prev_in_singleton = @current_in_singleton
      @current_in_singleton = true
      yield
      @current_in_singleton = prev_in_singleton
    end

    def current_method_visibility
      @current_method_visibility_stack.last
    end

    # start module / class scope visibility with public
    def add_new_method_visibility(new_visibility = :public)
      @current_method_visibility_stack << new_visibility
    end

    def in_method_visibility(visibility)
      add_new_method_visibility(visibility)
      yield
      remove_current_method_visibility
    end

    def remove_current_method_visibility
      @current_method_visibility_stack.pop
    end

    def change_current_method_visibility(visibility)
      @current_method_visibility_stack[-1] = visibility
    end

    def mark_as_module_function
      @module_function_flag = true
      change_current_method_visibility(:private)
    end

    def last_evaluated_tv(tv)
      @last_evaluated_tv = tv
    end

    def find_or_create_tv(node)
      tv = @type_vertex_registry.find(@source.path, node.node_id)
      return tv if tv

      tv =
        case node
        when Prism::RequiredParameterNode
          TypeVertex::Param.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::RequiredKeywordParameterNode
          TypeVertex::Kwparam.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::OptionalParameterNode
          TypeVertex::Param.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::OptionalKeywordParameterNode
          TypeVertex::Kwparam.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::LocalVariableReadNode
          TypeVertex::LvarRead.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::LocalVariableWriteNode, Prism::LocalVariableTargetNode
          TypeVertex::LvarWrite.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::InstanceVariableReadNode
          TypeVertex::IvarRead.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::InstanceVariableWriteNode
          TypeVertex::IvarWrite.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::CallNode
          TypeVertex::Call.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::IfNode
          TypeVertex::If.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::ArrayNode
          TypeVertex::Array.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::IntegerNode
          TypeVertex::Static.new(
            path: @source.path,
            name: node.value.to_s,
            node: node,
          )
        when Prism::StringNode
          TypeVertex::Static.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::HashNode
          TypeVertex::Hash.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::ConstantReadNode
          TypeVertex::ConstRead.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::ConstantPathNode
          TypeVertex::ConstRead.new(
            path: @source.path,
            name: node.name.to_s,
            node: node,
          )
        when Prism::StringNode
          TypeVertex::Static.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::InterpolatedStringNode
          TypeVertex::InterpolatedString.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::EmbeddedStatementsNode
          TypeVertex::EmbeddedStatements.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::SymbolNode
          TypeVertex::Static.new(
            path: @source.path,
            name: node.value.to_s,
            node: node,
          )
        when Prism::BreakNode
          TypeVertex::Break.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        when Prism::TrueNode, Prism::FalseNode, Prism::NilNode
          TypeVertex::Static.new(
            path: @source.path,
            name: node.class.name,
            node: node,
          )
        else
          pp node
          raise "unknown type variable node: #{node.class}"
        end

      @type_vertex_registry.add(tv)
      @node_registry.add(@source.path, tv)

      tv
    end

    private def build_qualified_const_name(const_names)
      (@current_scope[1..] + const_names).map(&:to_s).join("::")
    end

    private def in_if_cond(if_cond_tv)
      prev_in_if_cond_tv = @current_if_cond_tv
      @current_if_cond_tv = if_cond_tv
      yield
      @current_if_cond_tv = prev_in_if_cond_tv
    end

    private def in_if_cond?
      @current_if_cond_tv
    end

    private def in_scope(const_names)
      add_new_method_visibility
      @current_scope.push(*const_names)

      yield

      const_names.size.times { @current_scope.pop }
      remove_current_method_visibility
    end

    private def in_method(method_name, method_obj)
      prev_in_method_name = @current_method_name
      @current_method_name = method_name
      prev_method_obj = @current_method_obj
      @current_method_obj = method_obj
      prev_lvars = @lvars
      @lvars = []
      @return_tvs = []

      yield

      @lvars = prev_lvars
      @return_tvs.each do |tv|
        @current_method_obj.add_return_tv(tv)
      end
      @current_method_name = prev_in_method_name
      @current_method_obj = prev_method_obj
    end

    private def find_latest_lvar_tv(name)
      @lvars.reverse_each.find { |lvar| lvar.name == name }
    end

    private def in_method?
      @current_method_obj != nil
    end
  end
end
