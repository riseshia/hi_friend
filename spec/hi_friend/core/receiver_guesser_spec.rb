# frozen_string_literal: true

module HiFriend::Core
  RSpec.describe ReceiverGuesser do
    let(:db) { Storage.db }

    describe ".guess" do
      let(:receiver_rows) { [] }
      let(:receiver_respond_rows) { [] }
      let(:guessed_result) { described_class.guess(db: db, respond_methods: method_names) }
      let(:method_names) { [] }

      before do
        Receiver.insert_bulk(db: db, rows: receiver_rows)
        ReceiverRespond.insert_bulk(db: db, rows: receiver_respond_rows)
      end

      context "when db has no records" do
        let(:receiver_respond_rows) { [] }
        let(:method_names) { ["method_a"] }

        it "returns nil" do
          expect(guessed_result).to eq(Type.any)
        end
      end

      context "when exact one receiver matching" do
        let(:receiver_respond_rows) do
          [
            ["A", "method_a_a", "self"],
            ["A", "method_a_b", "self"],
            ["B", "method_b_a", "self"],
            ["B", "method_b_b", "self"],
          ]
        end
        let(:method_names) { ["method_a_a", "method_a_b"] }

        it "returns receiver name" do
          expect(guessed_result).to eq(Type.class_receiver("A"))
        end
      end

      context "when more than one receiver matching and methods are from mixin" do
        let(:receiver_rows) do
          [
            ["Class", "A", false, "/path/to/a.rb", 10, "hash123"],
            ["Class", "B", false, "/path/to/b.rb", 10, "hash123"],
            ["Class", "C", false, "/path/to/c.rb", 10, "hash123"],
            ["Module", "FeatureA", false, "/path/to/c.rb", 10, "hash123"],
          ]
        end
        let(:receiver_respond_rows) do
          [
            ["A", "included_method_a", "mixin"],
            ["B", "included_method_a", "mixin"],
            ["C", "method_c", "self"],
            ["FeatureA", "included_method_a", "self"],
          ]
        end
        let(:method_names) { ["included_method_a"] }

        xit "returns receiver name" do
          expect(guessed_result).to eq(Type.class_receiver("FeatureA"))
        end
      end

      context "when more than one receiver matching and methods are from superclass" do
        let(:receiver_rows) do
          [
            ["Class", "A", false, "/path/to/a.rb", 10, "hash123"],
            ["Class", "B", false, "/path/to/b.rb", 10, "hash123"],
            ["Class", "C", false, "/path/to/c.rb", 10, "hash123"],
            ["Class", "Parent", false, "/path/to/parent.rb", 10, "hash123"],
          ]
        end
        let(:receiver_respond_rows) do
          [
            ["A", "parent_method_a", "inherit"],
            ["B", "parent_method_a", "inherit"],
            ["C", "method_c", "self"],
            ["Parent", "parent_method_a", "self"],
          ]
        end
        let(:method_names) { ["parent_method_a"] }

        it "returns receiver name" do
          expect(guessed_result).to eq(Type.class_receiver("Parent"))
        end
      end

      context "when more than one receiver matching" do
        let(:receiver_respond_rows) do
          [
            ["A", "method_a", "self"],
            ["B", "method_b", "self"],
          ]
        end
        let(:method_names) { ["method_a", "method_b"] }

        it "returns receiver name" do
          expect(guessed_result).to eq(Type.any)
        end
      end
    end
  end
end
