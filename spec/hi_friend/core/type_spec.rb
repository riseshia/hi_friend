# frozen_string_literal: true

module HiFriend::Core
  module Type
    describe "#union" do
      let(:result) { Type.union(types) }

      context "when types are the different" do
        let(:types) do
          [
            Type.true,
            Type.nil,
          ]
        end

        it "return true | nil" do
          expect(result.to_ts).to eq("true | nil")
        end
      end

      context "when types are the same, some are different" do
        let(:types) do
          [
            Type.true,
            Type.nil,
            Type.nil,
          ]
        end

        it "return true | nil" do
          expect(result.to_ts).to eq("true | nil")
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
            Union.new([Type.true, Type.integer]),
            Type.nil,
          ]
        end

        it "return true" do
          expect(result.to_ts).to eq("true | Integer | nil")
        end
      end

      context "when types includes union and dup" do
        let(:types) do
          [
            Type.true,
            Union.new([Type.true, Type.nil]),
          ]
        end

        it "return true" do
          expect(result.to_ts).to eq("true | nil")
        end
      end

      context "when types are true and false" do
        let(:types) do
          [
            Type.true,
            Type.false,
          ]
        end

        it "return bool" do
          expect(result.to_ts).to eq("bool")
        end
      end

      context "when types are true and false" do
        let(:types) do
          [
            Type.true,
            Type.false,
          ]
        end

        it "return bool" do
          expect(result.to_ts).to eq("bool")
        end
      end
    end
  end
end
