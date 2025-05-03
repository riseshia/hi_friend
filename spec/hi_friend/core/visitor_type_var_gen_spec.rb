# frozen_string_literal: true

module HiFriend::Core
  describe Visitor do
    let(:db) { Storage.db }
    let(:const_registry) { HiFriend::Core.const_registry }
    let(:method_registry) { HiFriend::Core.method_registry }
    let(:type_vertex_registry) { HiFriend::Core.type_vertex_registry }
    let(:node_registry) { NodeRegistry.new }
    let(:source) { HiFriend::Core::Source.new(path: "sample/sample.rb", hash: "1234567890") }

    let(:visitor) do
      Visitor.new(
        db: db,
        const_registry: const_registry,
        method_registry: method_registry,
        type_vertex_registry: type_vertex_registry,
        node_registry: node_registry,
        source: source,
      )
    end

    before(:each) do
      const_registry.clear
      method_registry.clear
      type_vertex_registry.clear
      node_registry.clear
      parse_result = Prism.parse(code)
      parse_result.value.accept(visitor)
    end

    # context "type variable generation" do
    #   context "with lvar assign" do
    #     let(:code) do
    #       <<~CODE
    #         def hello
    #           a = 1
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a, one = type_vertex_registry.all
    #       expect(a.name).to eq("a")
    #       expect(one.name).to eq("1")
    #
    #       expect(a.dependencies).to eq([one])
    #       expect(one.dependents).to eq([a])
    #
    #       method_obj = method_registry.find("Object", "hello", singleton: false)
    #       expect(method_obj.return_tvs).to eq([a])
    #     end
    #   end
    #
    #   context "with lvar assign twice" do
    #     let(:code) do
    #       <<~CODE
    #         def hello
    #           a = 1
    #           a = 2
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, one, a1, two = type_vertex_registry.all
    #
    #       expect(a0.dependencies).to eq([one])
    #       expect(one.dependents).to eq([a0])
    #       expect(a1.dependencies).to eq([two])
    #       expect(two.dependents).to eq([a1])
    #
    #       method_obj = method_registry.find("Object", "hello", singleton: false)
    #       expect(method_obj.return_tvs).to eq([a1])
    #     end
    #   end
    #
    #   context "with lvar assign twice and chain" do
    #     let(:code) do
    #       <<~CODE
    #         def hello
    #           a = 1
    #           a = a + 2
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, one, a1, plus, a2, two = type_vertex_registry.all
    #
    #       expect(a0.dependencies).to eq([one])
    #       expect(one.dependents).to eq([a0])
    #       expect(a1.dependencies).to eq([plus])
    #       expect(plus.dependencies).to eq([a2, two])
    #       expect(plus.dependents).to eq([a1])
    #       expect(a2.dependencies).to eq([a0])
    #       expect(a2.dependents).to eq([plus])
    #       expect(two.dependents).to eq([plus])
    #
    #       method_obj = method_registry.find("Object", "hello", singleton: false)
    #       expect(method_obj.return_tvs).to eq([a1])
    #     end
    #   end
    #
    #   context "with method call" do
    #     let(:code) do
    #       <<~CODE
    #         def hello
    #           a + 1
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       plus, a0, one = type_vertex_registry.all
    #
    #       expect(plus.dependencies).to eq([a0, one])
    #       expect(a0.dependents).to eq([plus])
    #       expect(one.dependents).to eq([plus])
    #
    #       method_obj = method_registry.find("Object", "hello", singleton: false)
    #       expect(method_obj.return_tvs).to eq([plus])
    #     end
    #   end
    #
    #   context "with method arg and return" do
    #     let(:code) do
    #       <<~CODE
    #         def hello(a)
    #           return true if a > 1
    #           false
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, if_cond, gt, a1, one, true0, false0 = type_vertex_registry.all
    #
    #       expect(a0.dependents).to eq([a1])
    #       expect(if_cond.dependencies).to eq([true0])
    #       expect(gt.dependencies).to eq([a1, one])
    #       expect(a1.dependents).to eq([gt])
    #       expect(one.dependents).to eq([gt])
    #       expect(true0.dependents).to eq([if_cond])
    #       expect(true0.infer.to_ts).to eq("true")
    #       expect(false0.infer.to_ts).to eq("false")
    #
    #       method_obj = method_registry.find("Object", "hello", singleton: false)
    #       expect(method_obj.return_tvs).to eq([true0, false0])
    #     end
    #   end
    #
    #   context "with if and assign" do
    #     let(:code) do
    #       <<~CODE
    #         ret =
    #           if 1 > 2
    #             true
    #           else
    #             false
    #           end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       ret, if_cond, gt, one, two, true0, false0 = type_vertex_registry.all
    #
    #       expect(ret.dependencies).to eq([if_cond])
    #       expect(if_cond.dependencies).to eq([true0, false0])
    #       expect(if_cond.dependents).to eq([ret])
    #       expect(gt.dependencies).to eq([one, two])
    #       expect(one.dependents).to eq([gt])
    #       expect(two.dependents).to eq([gt])
    #       expect(true0.dependents).to eq([if_cond])
    #       expect(false0.dependents).to eq([if_cond])
    #     end
    #   end
    #
    #   context "with absolute const path return" do
    #     let(:code) do
    #       <<~CODE
    #         module C
    #         end
    #
    #         def hoge = ::C
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       c = type_vertex_registry.all.first
    #
    #       expect(c.name).to eq("C")
    #     end
    #   end
    #
    #   context "with const path return" do
    #     let(:code) do
    #       <<~CODE
    #         module C
    #           module D
    #             def hoge
    #               C::D
    #             end
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       c = type_vertex_registry.all.first
    #
    #       expect(c.name).to eq("C::D")
    #     end
    #   end
    #
    #   context "with symbol return" do
    #     let(:code) do
    #       <<~CODE
    #         def hoge
    #           :hoge
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       c = type_vertex_registry.all.first
    #
    #       expect(c.infer.to_ts).to eq(":hoge")
    #     end
    #   end
    #
    #   context "with attr_reader" do
    #     let(:code) do
    #       <<~CODE
    #         class C
    #           attr_reader :foo, "bar"
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       foo = method_registry.find("C", "foo", visibility: :public, singleton: false)
    #       bar = method_registry.find("C", "bar", visibility: :public, singleton: false)
    #
    #       expect(foo.name).to eq("foo")
    #       expect(foo.infer_return_type.to_ts).to eq("nil")
    #       expect(bar.name).to eq("bar")
    #       expect(bar.infer_return_type.to_ts).to eq("nil")
    #     end
    #   end
    #
    #   context "with attr_writer" do
    #     let(:code) do
    #       <<~CODE
    #         class C
    #           attr_writer :foo, "bar"
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       foo = method_registry.find("C", "foo=", visibility: :public, singleton: false)
    #       bar = method_registry.find("C", "bar=", visibility: :public, singleton: false)
    #
    #       expect(foo.name).to eq("foo=")
    #       expect(foo.infer_return_type.to_ts).to eq("nil")
    #       expect(bar.name).to eq("bar=")
    #       expect(bar.infer_return_type.to_ts).to eq("nil")
    #     end
    #   end
    #
    #   context "with attr_accessor" do
    #     let(:code) do
    #       <<~CODE
    #         class C
    #           attr_accessor :foo, "bar"
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       foo_read = method_registry.find("C", "foo", visibility: :public, singleton: false)
    #       foo_write = method_registry.find("C", "foo=", visibility: :public, singleton: false)
    #       bar_read = method_registry.find("C", "bar", visibility: :public, singleton: false)
    #       bar_write = method_registry.find("C", "bar=", visibility: :public, singleton: false)
    #
    #       expect(foo_read.name).to eq("foo")
    #       expect(foo_read.infer_return_type.to_ts).to eq("nil")
    #       expect(foo_write.name).to eq("foo=")
    #       expect(foo_write.infer_return_type.to_ts).to eq("nil")
    #       expect(bar_read.name).to eq("bar")
    #       expect(bar_read.infer_return_type.to_ts).to eq("nil")
    #       expect(bar_write.name).to eq("bar=")
    #       expect(bar_write.infer_return_type.to_ts).to eq("nil")
    #     end
    #   end
    #
    #   context "with ivar return" do
    #     let(:code) do
    #       <<~CODE
    #         class C
    #           def foo
    #             @foo
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       c = type_vertex_registry.all.last
    #
    #       expect(c.name).to eq("@foo")
    #       expect(c.infer.to_ts).to eq("nil")
    #     end
    #   end
    #
    #   context "with ivar write return" do
    #     let(:code) do
    #       <<~CODE
    #         class C
    #           def foo
    #             @foo = 1
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       foo, one = type_vertex_registry.all.last(2)
    #
    #       expect(foo.name).to eq("@foo")
    #       expect(foo.infer.to_ts).to eq("Integer")
    #     end
    #   end
    #
    #   context "with ivar read/write" do
    #     let(:code) do
    #       <<~CODE
    #         class C
    #           def foo_init
    #             @foo = 1
    #           end
    #
    #           def foo
    #             @foo
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       foo0, one, foo1 = type_vertex_registry.all.last(3)
    #
    #       expect(foo1.name).to eq("@foo")
    #       expect(foo1.infer.to_ts).to eq("Integer")
    #     end
    #   end
    #
    #   context "with lvar with int array" do
    #     let(:code) do
    #       <<~CODE
    #         arr = [1, 2]
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       arr_var, arr, one, two = type_vertex_registry.all
    #
    #       expect(arr.name).to eq("Prism::ArrayNode")
    #       expect(arr.infer.to_ts).to eq("[Integer]")
    #     end
    #   end
    #
    #   context "with params with default value" do
    #     let(:code) do
    #       <<~CODE
    #         def foo(a, b = 1)
    #           a + b
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, b0, one, plus, a1, a2 = type_vertex_registry.all
    #
    #       expect(b0.infer.to_ts).to eq("Integer")
    #     end
    #   end
    #
    #   context "with keyword params" do
    #     let(:code) do
    #       <<~CODE
    #         def foo(a, b:)
    #           a + b
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, b0, plus, a1, a2 = type_vertex_registry.all
    #
    #       expect(b0.infer.to_ts).to eq("any")
    #     end
    #   end
    #
    #   context "with keyword params with default value" do
    #     let(:code) do
    #       <<~CODE
    #         def foo(a, b: 1)
    #           a + b
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, b0, one, plus, a1, a2 = type_vertex_registry.all
    #
    #       expect(b0.infer.to_ts).to eq("Integer")
    #     end
    #   end
    #
    #   context "with multi write node with same node on right side" do
    #     let(:code) do
    #       <<~CODE
    #         def foo
    #           a, b = 1, 2
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, b0, array, one, two = type_vertex_registry.all
    #
    #       expect(a0.dependencies).to eq([one])
    #       expect(b0.dependencies).to eq([two])
    #       expect(a0.infer.to_ts).to eq("Integer")
    #       expect(b0.infer.to_ts).to eq("Integer")
    #       expect(array.infer.to_ts).to eq("[Integer]")
    #     end
    #   end
    #
    #   context "with multi write node with one node on right side" do
    #     let(:code) do
    #       <<~CODE
    #         def foo
    #           arr = [1, 2]
    #           a, b = arr
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       skip "we need sized array for this"
    #       arr0, fixed_arr, one, two, a0, b0, arr1 = type_vertex_registry.all
    #
    #       expect(a0.dependencies).to eq([arr1])
    #       expect(b0.dependencies).to eq([arr1])
    #       expect(arr1.dependencies).to eq([fixed_arr])
    #       expect(arr1.dependents).to eq([a0, b0])
    #       expect(fixed_arr.dependencies).to eq([one, two])
    #       expect(fixed_arr.dependents).to eq([arr1])
    #       expect(one.dependents).to eq([fixed_arr])
    #       expect(two.dependents).to eq([fixed_arr])
    #     end
    #   end
    #
    #   context "with loop" do
    #     let(:code) do
    #       <<~CODE
    #         def foo
    #           loop do
    #             1
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       skip "we need to add Kernel#loop signature"
    #
    #       loop_call, one = type_vertex_registry.all
    #
    #       expect(loop_call.infer.to_ts).to eq("nil")
    #     end
    #   end
    #
    #   context "with break with no args" do
    #     let(:code) do
    #       <<~CODE
    #         def foo
    #           loop do
    #             break if true
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       skip "we need to handle loop"
    #       loop_call, if_cond, true0, break_node = type_vertex_registry.all
    #
    #       expect(loop_call.infer.to_ts).to eq("nil")
    #     end
    #   end
    #
    #   context "with break with args" do
    #     let(:code) do
    #       <<~CODE
    #         def foo
    #           loop do
    #             break 1, 2 if true
    #           end
    #         end
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       skip "we need to handle loop"
    #       loop_call, if_cond, true0, break_node, one, two = type_vertex_registry.all
    #
    #       expect(loop_call.infer.to_ts).to eq("1 | 2 | nil")
    #     end
    #   end
    #
    #   context "with static hash" do
    #     let(:code) do
    #       <<~CODE
    #         a = { foo: 1, "bar" => 2 }
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, foo, one, bar, two = type_vertex_registry.all
    #
    #       expect(a0.infer.to_ts).to eq('{ foo: Integer, "bar" => Integer }')
    #     end
    #   end
    #
    #   context "with hash which has variable as value" do
    #     let(:code) do
    #       <<~CODE
    #         b = 1
    #         a = { foo: b, "bar" => 2 }
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       b0, one, a0, foo, b1, bar, two = type_vertex_registry.all
    #
    #       expect(a0.infer.to_ts).to eq('{ foo: Integer, "bar" => Integer }')
    #     end
    #   end
    #
    #   context "with class method" do
    #     let(:code) do
    #       <<~CODE
    #         class A
    #           def self.hello = 1
    #         end
    #
    #         a_class = A
    #         b = a_class.hello
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       one, a_class0, const_a, b0, method_hello, a_class1 = type_vertex_registry.all
    #
    #       expect(a_class0.infer.to_ts).to eq('singleton(A)')
    #       expect(b0.infer.to_ts).to eq("Integer")
    #     end
    #   end
    #
    #   context "with string interpolation" do
    #     let(:code) do
    #       <<~CODE
    #         a = "foo"
    #         b = "bar\#{a}"
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, foo, b0, itpl_str, bar, embedded, a1 = type_vertex_registry.all
    #
    #       expect(a0.infer.to_ts).to eq('"foo"')
    #       expect(b0.infer.to_ts).to eq("String")
    #       expect(embedded.infer.to_ts).to eq('"foo"')
    #       expect(itpl_str.infer.to_ts).to eq("String")
    #     end
    #   end
    #
    #   context "with default method visibility on Object" do
    #     let(:code) do
    #       <<~CODE
    #         def foo = 1
    #       CODE
    #     end
    #
    #     it "registers foo as private method" do
    #       method_obj = method_registry.find("Object", "foo", visibility: :private, singleton: false)
    #       expect(method_obj).not_to be_nil
    #       expect(method_obj.visibility).to eq(:private)
    #     end
    #   end
    #
    #   context "with method visibility after no arg public" do
    #     let(:code) do
    #       <<~CODE
    #         public
    #         def foo = 1
    #       CODE
    #     end
    #
    #     it "registers foo as public method" do
    #       method_obj = method_registry.find("Object", "foo", singleton: false)
    #       expect(method_obj).not_to be_nil
    #       expect(method_obj.visibility).to eq(:public)
    #     end
    #   end
    #
    #   context "with method visibility set with def" do
    #     let(:code) do
    #       <<~CODE
    #         public def foo = 1
    #         def bar = 2
    #       CODE
    #     end
    #
    #     it "registers foo as public method" do
    #       method_obj = method_registry.find("Object", "foo", singleton: false)
    #       expect(method_obj).not_to be_nil
    #       expect(method_obj.visibility).to eq(:public)
    #     end
    #
    #     it "registers bar as private method" do
    #       method_obj = method_registry.find("Object", "bar", singleton: false)
    #       expect(method_obj).not_to be_nil
    #       expect(method_obj.visibility).to eq(:private)
    #     end
    #   end
    #
    #   context "with method visibility set with method names" do
    #     let(:code) do
    #       <<~CODE
    #         def foo = 1
    #         def bar = 2
    #         def baz = 3
    #         public :foo, "bar"
    #       CODE
    #     end
    #
    #     it "registers foo, bar as public method" do
    #       foo_obj = method_registry.find("Object", "foo", singleton: false)
    #       expect(foo_obj).not_to be_nil
    #       expect(foo_obj.visibility).to eq(:public)
    #
    #       foo_obj = method_registry.find("Object", "foo", singleton: false)
    #       expect(foo_obj).not_to be_nil
    #       expect(foo_obj.visibility).to eq(:public)
    #     end
    #
    #     it "registers baz as private method" do
    #       method_obj = method_registry.find("Object", "baz", singleton: false)
    #       expect(method_obj).not_to be_nil
    #       expect(method_obj.visibility).to eq(:private)
    #     end
    #   end
    #
    #   context "with required params" do
    #     let(:code) do
    #       <<~CODE
    #         def foo(a, b)
    #           a + b
    #         end
    #
    #         foo(1, 2)
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       a0, b0, plus, a1, b1, foo, one, two = type_vertex_registry.all
    #
    #       plus.infer
    #
    #       expect(a0.inferred_type.to_ts).to eq("#+")
    #       expect(b0.inferred_type.to_ts).to eq("any")
    #     end
    #   end
    #
    #   context "with required kw params" do
    #     let(:code) do
    #       <<~CODE
    #         def foo(b, a:)
    #           a + b
    #         end
    #
    #         foo(1, a: 2)
    #       CODE
    #     end
    #
    #     it "registers all" do
    #       b0, a0, plus, a1, b1, foo, one, two = type_vertex_registry.all
    #
    #       plus.infer
    #
    #       expect(a0.inferred_type.to_ts).to eq("#+")
    #       expect(b0.inferred_type.to_ts).to eq("any")
    #     end
    #   end
    # end
  end
end
