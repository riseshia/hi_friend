# frozen_string_literal: true

module HiFriend::Core
  describe "ParseReceivers" do
    let(:db) do
      Storage.new
    end
    let(:const_registry) { HiFriend::Core.const_registry }
    let(:method_registry) { HiFriend::Core.method_registry }
    let(:type_vertex_registry) { HiFriend::Core.type_vertex_registry }
    let(:node_registry) { NodeRegistry.new }

    let(:visitor) do
      Visitor.new(
        db: db,
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

    def expect_class_exists(fqname)
      receiver = Receiver.find_by_fqname(db, fqname)
      expect(receiver).not_to be_nil

      singleton_receiver = Receiver.find_by_fqname(db, "singleton(#{fqname})")
      expect(singleton_receiver).not_to be_nil
    end

    context "when simple class" do
      let(:code) do
        <<~CODE
          class Post
          end
        CODE
      end

      it "registers one class" do
        expect_class_exists("Post")
      end
    end

    context "when class with const path" do
      let(:code) do
        <<~CODE
          class Post::Comment
          end
        CODE
      end

      it "registers one class" do
        expect_class_exists("Post::Comment")
      end
    end

    context "when class in class" do
      let(:code) do
        <<~CODE
          class Post
            class Comment
            end
          end
        CODE
      end

      it "registers one class" do
        expect_class_exists("Post::Comment")
      end
    end

    context "when class in module" do
      let(:code) do
        <<~CODE
          module Post
            class Comment
            end
          end
        CODE
      end

      it "registers one class" do
        expect_class_exists("Post::Comment")
      end
    end

    context "when every const with constant path" do
      let(:code) do
        <<~CODE
          module A::B
            class C::D
              class E::F
              end
            end
          end
        CODE
      end

      it "registers one class" do
        expect_class_exists("A::B::C::D::E::F")
      end
    end

    context "when const with assign" do
      let(:code) do
        <<~CODE
          CustomError = Class.new(StandardError)
        CODE
      end

      xit "registers one class" do
        expect_class_exists("CustomError")
      end
    end
  end
end
