# frozen_string_literal: true

module HiFriend
  describe LocToNodeMapper do
    describe "#lookup" do
      let(:code) do
        <<~CODE
          module App
            class Post
              def initialize(title, body)
                @title = title
                @body = body
              end

              def title
                @title
              end

              def self.find(id)
                Repository.find(Post, id)
              end
            end
          end
        CODE
      end
      let(:node) { Prism.parse(code).value }

      it "return module" do
        pos = HiFriend::CodePosition.new(1, 1)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:module_node)
      end

      it "return App" do
        pos = HiFriend::CodePosition.new(1, 7)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:constant_read_node)
      end

      it "return class" do
        pos = HiFriend::CodePosition.new(2, 3)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:class_node)
      end

      it "return def initialize" do
        pos = HiFriend::CodePosition.new(3, 4)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:def_node)
      end

      it "return arg title of initialize" do
        pos = HiFriend::CodePosition.new(3, 19)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:required_parameter_node)
      end

      it "return ivar title" do
        pos = HiFriend::CodePosition.new(9, 6)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:instance_variable_read_node)
      end

      it "return call" do
        pos = HiFriend::CodePosition.new(13, 19)
        result = described_class.lookup(node, pos)
        expect(result.type).to eq(:call_node)
      end
    end
  end
end
