# frozen_string_literal: true

module HiFriend::Core
  describe Visitor do
    let(:const_registry) { HiFriend::Core.const_registry }
    let(:method_registry) { HiFriend::Core.method_registry }
    let(:type_vertex_registry) { HiFriend::Core.type_vertex_registry }
    let(:node_registry) { NodeRegistry.new }
    let(:visitor) do
      Visitor.new(
        const_registry: const_registry,
        method_registry: method_registry,
        type_vertex_registry: type_vertex_registry,
        node_registry: node_registry,
        file_path: "sample/sample.rb",
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

    context "when simple class" do
      let(:code) do
        <<~CODE
          class Post
          end
        CODE
      end

      it "registers class" do
        expect(const_registry.find("Post")).not_to be_nil
      end
    end

    context "with const read" do
      let(:code) do
        <<~CODE
        class C
          def foo
            C
          end
        end
        CODE
      end

      it "registers all" do
        ref_const = type_vertex_registry.all.first

        expect(ref_const.infer.to_ts).to eq("singleton(C)")
      end
    end

    context "with const path read" do
      let(:code) do
        <<~CODE
        module A
          class B
            def foo
              A::B
            end
          end
        end
        CODE
      end

      it "registers all" do
        ref_const = type_vertex_registry.all.first

        expect(ref_const.infer.to_ts).to eq("singleton(A::B)")
      end
    end

    context "with absolute const path read" do
      let(:code) do
        <<~CODE
        module A
          module B
            module A
              class B
                def foo = ::A
                def bar = A
                def baz = A::B
                def qux = ::A::B
              end
            end
          end
        end
        CODE
      end

      it "registers all" do
        abs_const, rel_const0, rel_const1, rel_const2 = type_vertex_registry.all

        expect(abs_const.infer.to_ts).to eq("singleton(A)")
        expect(rel_const0.infer.to_ts).to eq("singleton(A::B::A)")
        expect(rel_const1.infer.to_ts).to eq("singleton(A::B::A::B)")
        expect(rel_const2.infer.to_ts).to eq("singleton(A::B)")
      end
    end

    context "with class which inherit unexist const" do
      let(:code) do
        <<~CODE
        class C < A::B
          def foo
            1
          end
        end
        CODE
      end

      it "registers all" do
        one = type_vertex_registry.all.first

        expect(one.infer.to_ts).to eq("singleton(C)")
      end
    end

    context "with class with constant path" do
      let(:code) do
        <<~CODE
        class A::B
          def foo
            1
          end
        end
        CODE
      end

      it "registers all" do
        one = type_vertex_registry.all.first

        expect(one.infer.to_ts).to eq("Integer")
      end
    end

    context "with class with constant path" do
      let(:code) do
        <<~CODE
        module A
          class A0; end

          module B
            class C < A0
            end
          end
        end
        CODE
      end

      it "registers all" do
        c = const_registry.find("A::B::C")

        expect(c.superclass.name).to eq("A::A0")
      end
    end
  end
end
