# frozen_string_literal: true

module HiFriend::Core
  module Type
    describe "#union" do
      let(:result) { Type.union(types) }

      context "when types are the different" do
        let(:types) do
          [
            Type.true,
            Type.false,
          ]
        end

        it "return true | false" do
          expect(result.to_human_s).to eq("true | false")
        end
      end

      context "when types are the same, some are different" do
        let(:types) do
          [
            Type.true,
            Type.false,
            Type.false,
          ]
        end

        it "return true | false" do
          expect(result.to_human_s).to eq("true | false")
        end
      end

      context "when types are the same" do
        let(:types) do
          [
            Type.true,
            Type.true,
          ]
        end

        it "return true" do
          expect(result).to be_a(Type::True)
        end
      end

      context "when types includes union" do
        let(:types) do
          [
            Union.new([Type.true, Type.false]),
            Type.nil,
          ]
        end

        it "return true" do
          expect(result.to_human_s).to eq("true | false | nil")
        end
      end

      context "when types includes union and dup" do
        let(:types) do
          [
            Type.true,
            Union.new([Type.true, Type.false]),
          ]
        end

        it "return true" do
          expect(result.to_human_s).to eq("true | false")
        end
      end
    end
  end
end
