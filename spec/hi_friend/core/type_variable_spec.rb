# frozen_string_literal: true

module HiFriend::Core
  module TypeVertex
    describe "TypeVertex" do
      def true_tv
        TypeVertex::Static.new(path: "path", name: "Prism::TrueNode", node: nil).tap do |tv|
          tv.correct_type(Type.true)
        end
      end

      def false_tv
        TypeVertex::Static.new(path: "path", name: "Prism::FalseNode", node: nil).tap do |tv|
          tv.correct_type(Type.false)
        end
      end

      def integer_tv
        TypeVertex::Static.new(path: "path", name: "Prism::IntegerNode", node: nil).tap do |tv|
          tv.correct_type(Type.integer)
        end
      end

      describe Static do
        describe "#infer" do
          let(:tv) do
            described_class.new(path: "path", name: "Prism::TrueNode", node: nil).tap do |tv|
              tv.correct_type(Type.true)
            end
          end

          it "return only one type" do
            expect(tv.infer.to_ts).to eq("true")
          end
        end
      end

      describe LvarWrite do
        describe "#infer" do
          let(:tv) do
            described_class.new(path: "path", name: "a", node: nil).tap do |tv|
              tv.add_dependency(true_tv)
            end
          end

          it "return right hand value" do
            expect(tv.infer.to_ts).to eq("true")
          end
        end
      end

      describe LvarRead do
        describe "#infer" do
          let(:tv) do
            described_class.new(path: "path", name: "a", node: nil).tap do |tv|
              lvar_write_tv = LvarWrite.new(path: "path", name: "a", node: nil)
              lvar_write_tv.add_dependency(true_tv)
              tv.add_dependency(lvar_write_tv)
            end
          end

          it "return right hand value" do
            expect(tv.infer.to_ts).to eq("true")
          end
        end
      end

      describe Param do
        describe "#infer" do
          let(:tv) do
            described_class.new(path: "path", name: "a", node: nil).tap do |tv|
              method_obj = Method.new(id: "method_id", name: "a", receiver_type: Type::Const.new("Object"), node: nil, visibility: :public)
              tv.add_method_obj(method_obj)
              method_obj.add_arg_tv(tv)
            end
          end

          it "return right hand value" do
            expect(tv.infer.to_ts).to eq("any")
          end
        end
      end

      describe Call do
        describe "#infer" do
          # 1 + 2
          let(:tv) do
            node = double(Prism::CallNode, name: :+)
            allow(node).to receive(:receiver).and_return(double(Prism::IntegerNode))

            described_class.new(path: "path", name: "+", node: node).tap do |tv|
              one = integer_tv
              two = integer_tv

              tv.add_receiver_tv(one)
              tv.add_dependency(two)

              node = double(Prism::CallNode, name: :+)

              HiFriend::Core.method_registry.create(
                receiver_name: "Integer",
                name: "+",
                node: node,
                path: "path",
                singleton: false,
                visibility: :public,
              )
              method_obj = HiFriend::Core.method_registry.find("Integer", "+", visibility: :public, singleton: false)
              method_obj.add_arg_type(0, Type.integer)
              method_obj.add_return_type(Type.integer)
            end
          end

          after do
            HiFriend::Core.method_registry.clear
          end

          it "return right hand value" do
            expect(tv.infer.to_ts).to eq("Integer")
          end
        end
      end

      describe If do
        describe "#infer" do
          # if true
          #   true
          # else
          #   false
          # end
          let(:tv) do
            described_class.new(path: "path", name: "Prism::IfNode", node: nil).tap do |tv|
              true_stmt = true_tv
              false_stmt = false_tv

              tv.add_dependency(true_stmt)
              tv.add_dependency(false_stmt)
            end
          end

          it "return right hand value" do
            expect(tv.infer.to_ts).to eq("bool")
          end
        end
      end
    end
  end
end
