# frozen_string_literal: true

module HiFriend
  describe RbsTypeConverter do
    describe "#convert" do
      let(:builder) do
        loader = RBS::EnvironmentLoader.new
        environment = RBS::Environment.from_loader(loader).resolve_type_names
        RBS::DefinitionBuilder.new(env: environment)
      end

      Type = HiFriend::Core::Type

      def expect_type_equals(rbs_type, hi_friend_type)
        rbs_type = RBS::Parser.parse_type(rbs_type)
        result = described_class.convert(builder, rbs_type)

        expect(result).to eq(hi_friend_type)
      end

      it "convert void to void" do
        expect_type_equals("void", Type.void)
      end

      it "convert untyped to any" do
        expect_type_equals("untyped", Type.any)
      end

      it "convert bool to bool" do
        expect_type_equals("bool", Type.bool)
      end

      it "convert nil to nil" do
        expect_type_equals("nil", Type.nil)
      end

      it "convert top to any" do
        expect_type_equals("top", Type.any)
      end

      it "convert bot to any" do
        expect_type_equals("bot", Type.any)
      end

      it "convert self to self" do
        expect_type_equals("self", Type.self0)
      end

      it "convert class to class" do
        expect_type_equals("class", Type.class0)
      end

      it "convert instance to instance" do
        expect_type_equals("instance", Type.instance)
      end

      it "convert singleton class to singleton class" do
        expect_type_equals("singleton(String)", Type.const("String", singleton: true))
      end

      it "convert symbol to Symbol" do
        expect_type_equals("symbol", Type.const("Symbol", singleton: false))
      end

      it "convert Symbol to Symbol" do
        expect_type_equals("Symbol", Type.const("Symbol", singleton: false))
      end
    end
  end
end
