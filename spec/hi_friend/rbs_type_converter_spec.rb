# frozen_string_literal: true

module HiFriend
  describe RbsTypeConverter do
    describe "#convert" do
      Type = HiFriend::Core::Type

      def expect_type_equals(rbs_type, hi_friend_type)
        rbs_type = RBS::Parser.parse_type(rbs_type)
        result = described_class.convert(rbs_type)

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

      it "convert class to class" do
        expect_type_equals("String", Type.const("String", singleton: false))
      end
    end
  end
end
