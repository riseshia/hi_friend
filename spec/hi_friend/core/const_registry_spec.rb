# frozen_string_literal: true

module HiFriend::Core
  describe ConstRegistry do
    let(:const_registry) { HiFriend::Core.const_registry }

    before(:each) do
      const_registry.clear
    end

    describe "#lookup" do
      context "without scope" do
        before do
          const_registry.add("A", nil, "test_file.rb")
          const_registry.add("B", nil, "test_file.rb")
          const_registry.add("B::A", nil, "test_file.rb")
        end

        it "returns A" do
          const = const_registry.lookup("", "A")
          expect(const.name).to eq("A")
        end

        it "returns B::A" do
          const = const_registry.lookup("", "B::A")
          expect(const.name).to eq("B::A")
        end
      end

      context "with scope" do
        before do
          const_registry.add("A", nil, "test_file.rb")
          const_registry.add("A::B0", nil, "test_file.rb")
          const_registry.add("A::B0::C", nil, "test_file.rb")
          const_registry.add("A::B1", nil, "test_file.rb")
          const_registry.add("B0", nil, "test_file.rb")
          const_registry.add("B0::C", nil, "test_file.rb")
        end

        it "returns A" do
          const = const_registry.lookup("A", "A")
          expect(const.name).to eq("A")
        end

        it "returns A::B0" do
          const = const_registry.lookup("A::B0", "B0")
          expect(const.name).to eq("A::B0")
        end

        it "returns A::B1" do
          const = const_registry.lookup("A::B0", "B1")
          expect(const.name).to eq("A::B1")
        end

        it "returns B0" do
          const = const_registry.lookup("B0::C", "B0")
          expect(const.name).to eq("B0")
        end
      end
    end
  end
end
