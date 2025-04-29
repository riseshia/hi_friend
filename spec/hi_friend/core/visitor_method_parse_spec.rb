# frozen_string_literal: true

module HiFriend::Core
  describe Visitor do
    let(:db) { Storage.db }
    let(:const_registry) { ConstRegistry.new }
    let(:method_registry) { MethodRegistry.new }
    let(:type_vertex_registry) { TypeVertexRegistry.new }
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
      parse_result = Prism.parse(code)
      parse_result.value.accept(visitor)
    end

    context "when simple def" do
      let(:code) do
        <<~CODE
          def hello = 1
        CODE
      end

      it "registers method" do
        expect(method_registry.find("Object", "hello", visibility: :private, singleton: false)).not_to be_nil
      end
    end

    context "when class with public instance method" do
      let(:code) do
        <<~CODE
          class Post
            def hello = 1
          end
        CODE
      end

      it "registers all" do
        expect(method_registry.find("Post", "hello", visibility: :public, singleton: false)).not_to be_nil
      end
    end

    context "when class with private instance method" do
      # XXX: comment out because of the error
      #      We need to handle inline visiblity methods(public, private, protected) correctly to pass this test.
      # context "when inline private" do
      #   let(:code) do
      #     <<~CODE
      #       class Post
      #         private def hello = 1
      #       end
      #     CODE
      #   end
      #
      #   it "registers method" do
      #     skip
      #     expect(method_registry.find("Post", "hello", visibility: :private, singleton: false)).not_to be_nil
      #   end
      # end

      context "when private declare" do
        let(:code) do
          <<~CODE
            class Post
              private
              def hello = 1
            end
          CODE
        end

        it "registers method" do
          skip
          expect(method_registry.find("Post", "hello", visibility: :private, singleton: false)).not_to be_nil
        end
      end
    end

    context "when class with class method" do
      context "with self." do
        let(:code) do
          <<~CODE
            class Post
              def self.hello = 1
            end
          CODE
        end

        it "registers all" do
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end

      context "with open self" do
        let(:code) do
          <<~CODE
            class Post
              class << self
                def hello = 1
              end
            end
          CODE
        end

        it "registers all" do
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end

      context "with self. in open self" do
        let(:code) do
          <<~CODE
            class Post
              class << self
                def self.hello = 1
              end
            end
          CODE
        end

        it "registers all" do
          skip
          expect(method_registry.find("Post", "hello", visibility: :public, singleton: true)).not_to be_nil
        end
      end
    end
  end
end
