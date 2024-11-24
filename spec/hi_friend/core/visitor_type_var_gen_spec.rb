# frozen_string_literal: true

module HiFriend::Core
  describe Visitor do
    let(:const_registry) { ConstRegistry.new }
    let(:method_registry) { MethodRegistry.new }
    let(:type_var_registry) { TypeVariableRegistry.new }
    let(:visitor) do
      Visitor.new(
        const_registry: const_registry,
        method_registry: method_registry,
        type_var_registry: type_var_registry,
        file_path: "sample/sample.rb",
      )
    end

    before(:each) do
      parse_result = Prism.parse(code)
      parse_result.value.accept(visitor)
    end

    context "type variable generation" do
      context "with lvar assign" do
        let(:code) do
          <<~CODE
            def hello
              a = 1
            end
          CODE
        end

        it "registers all" do
          a, one = type_var_registry.all
          expect(a.name).to eq("a")
          expect(one.name).to eq("1")

          expect(a.dependencies).to eq([one])
          expect(one.dependents).to eq([a])

          method_obj = method_registry.find("", "hello", visibility: :public, singleton: false)
          expect(method_obj.return_tvs).to eq([a])
        end
      end

      context "with lvar assign twice" do
        let(:code) do
          <<~CODE
            def hello
              a = 1
              a = 2
            end
          CODE
        end

        it "registers all" do
          a0, one, a1, two = type_var_registry.all

          expect(a0.dependencies).to eq([one])
          expect(one.dependents).to eq([a0])
          expect(a1.dependencies).to eq([two])
          expect(two.dependents).to eq([a1])

          method_obj = method_registry.find("", "hello", visibility: :public, singleton: false)
          expect(method_obj.return_tvs).to eq([a1])
        end
      end

      context "with lvar assign twice and chain" do
        let(:code) do
          <<~CODE
            def hello
              a = 1
              a = a + 2
            end
          CODE
        end

        it "registers all" do
          a0, one, a1, plus, a2, two = type_var_registry.all

          expect(a0.dependencies).to eq([one])
          expect(one.dependents).to eq([a0])
          expect(a1.dependencies).to eq([plus])
          expect(plus.dependencies).to eq([a2, two])
          expect(plus.dependents).to eq([a1])
          expect(plus.scope).to eq("")
          expect(a2.dependencies).to eq([a0])
          expect(a2.dependents).to eq([plus])
          expect(two.dependents).to eq([plus])

          method_obj = method_registry.find("", "hello", visibility: :public, singleton: false)
          expect(method_obj.return_tvs).to eq([a1])
        end
      end

      context "with method call" do
        let(:code) do
          <<~CODE
            def hello
              a + 1
            end
          CODE
        end

        it "registers all" do
          plus, a0, one = type_var_registry.all

          expect(plus.dependencies).to eq([a0, one])
          expect(a0.dependents).to eq([plus])
          expect(one.dependents).to eq([plus])

          method_obj = method_registry.find("", "hello", visibility: :public, singleton: false)
          expect(method_obj.return_tvs).to eq([plus])
        end
      end

      context "with method arg and return" do
        let(:code) do
          <<~CODE
            def hello(a)
              return true if a > 1
              false
            end
          CODE
        end

        it "registers all" do
          a0, if_cond, gt, a1, one, true0, false0 = type_var_registry.all

          expect(a0.dependents).to eq([a1])
          expect(if_cond.dependencies).to eq([true0])
          expect(gt.dependencies).to eq([a1, one])
          expect(a1.dependents).to eq([gt])
          expect(one.dependents).to eq([gt])
          expect(true0.dependents).to eq([if_cond])
          expect(true0.inference.to_human_s).to eq("true")
          expect(false0.inference.to_human_s).to eq("false")

          method_obj = method_registry.find("", "hello", visibility: :public, singleton: false)
          expect(method_obj.return_tvs).to eq([true0, false0])
        end
      end

      context "with if and assign" do
        let(:code) do
          <<~CODE
            ret =
              if 1 > 2
                true
              else
                false
              end
          CODE
        end

        it "registers all" do
          ret, if_cond, gt, one, two, true0, false0 = type_var_registry.all

          expect(ret.dependencies).to eq([if_cond])
          expect(if_cond.dependencies).to eq([true0, false0])
          expect(if_cond.dependents).to eq([ret])
          expect(gt.dependencies).to eq([one, two])
          expect(one.dependents).to eq([gt])
          expect(two.dependents).to eq([gt])
          expect(true0.dependents).to eq([if_cond])
          expect(false0.dependents).to eq([if_cond])
        end
      end

      context "with const return" do
        let(:code) do
          <<~CODE
            def hoge
              C
            end
          CODE
        end

        it "registers all" do
          c = type_var_registry.all.first

          expect(c.name).to eq("C")
        end
      end

      context "with absolute const path return" do
        let(:code) do
          <<~CODE
            def hoge
              ::C
            end
          CODE
        end

        it "registers all" do
          c = type_var_registry.all.first

          expect(c.name).to eq("C")
        end
      end

      context "with const path return" do
        let(:code) do
          <<~CODE
            def hoge
              C::D
            end
          CODE
        end

        it "registers all" do
          c = type_var_registry.all.first

          expect(c.name).to eq("C::D")
        end
      end

      context "with symbol return" do
        let(:code) do
          <<~CODE
            def hoge
              :hoge
            end
          CODE
        end

        it "registers all" do
          c = type_var_registry.all.first

          expect(c.inference.to_human_s).to eq(":hoge")
        end
      end

      context "with ivar return" do
        let(:code) do
          <<~CODE
            class C
              def foo
                @foo
              end
            end
          CODE
        end

        it "registers all" do
          c = type_var_registry.all.last

          expect(c.name).to eq("@foo")
          expect(c.inference.to_human_s).to eq("nil")
        end
      end

      context "with ivar write return" do
        let(:code) do
          <<~CODE
            class C
              def foo
                @foo = 1
              end
            end
          CODE
        end

        it "registers all" do
          foo, one = type_var_registry.all.last(2)

          expect(foo.name).to eq("@foo")
          expect(foo.inference.to_human_s).to eq("Integer")
        end
      end

      context "with ivar read/write" do
        let(:code) do
          <<~CODE
            class C
              def foo_init
                @foo = 1
              end

              def foo
                @foo
              end
            end
          CODE
        end

        it "registers all" do
          foo0, one, foo1 = type_var_registry.all.last(3)

          expect(foo1.name).to eq("@foo")
          expect(foo1.inference.to_human_s).to eq("Integer")
        end
      end

      context "with lvar with int array" do
        let(:code) do
          <<~CODE
            arr = [1, 2]
          CODE
        end

        it "registers all" do
          arr_var, arr, one, two = type_var_registry.all

          expect(arr.name).to eq("Prism::ArrayNode")
          expect(arr.inference.to_human_s).to eq("[Integer]")
        end
      end

      context "with params with default value" do
        let(:code) do
          <<~CODE
            def foo(a, b = 1)
              a + b
            end
          CODE
        end

        it "registers all" do
          a0, b0, one, plus, a1, a2 = type_var_registry.all

          expect(b0.inference.to_human_s).to eq("Integer")
        end
      end

      context "with keyword params" do
        let(:code) do
          <<~CODE
            def foo(a, b:)
              a + b
            end
          CODE
        end

        it "registers all" do
          a0, b0, plus, a1, a2 = type_var_registry.all

          expect(b0.inference.to_human_s).to eq("any")
        end
      end

      context "with keyword params with default value" do
        let(:code) do
          <<~CODE
            def foo(a, b: 1)
              a + b
            end
          CODE
        end

        it "registers all" do
          a0, b0, one, plus, a1, a2 = type_var_registry.all

          expect(b0.inference.to_human_s).to eq("Integer")
        end
      end
    end
  end
end
