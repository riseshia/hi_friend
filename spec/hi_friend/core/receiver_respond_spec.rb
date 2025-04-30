# frozen_string_literal: true

module HiFriend::Core
  RSpec.describe ReceiverRespond do
    let(:db) { Storage.db }

    describe ".insert_bulk" do
      it "inserts new records" do
        rows = [
          ["A::B", "foo", "self"],
          ["A::B", "bar", "self"],
        ]

        described_class.insert_bulk(
          db: db,
          rows: rows
        )

        rows.each do |(receiver_fqname, method_name, source)|
          model = described_class.find_by(
            db: db,
            receiver_fqname: receiver_fqname,
            method_name: method_name
          )
          expect(model).to be_a(ReceiverRespond)

          expect(model.receiver_fqname).to eq(receiver_fqname)
          expect(model.method_name).to eq(method_name)
          expect(model.source).to eq(source)
        end
      end
    end

    describe ".insert" do
      it "inserts new record" do
        described_class.insert(
          db: db,
          receiver_fqname: "A::B",
          method_name: "foo",
          source: "self"
        )

        model = described_class.find_by(
          db: db,
          receiver_fqname: "A::B",
          method_name: "foo"
        )
        expect(model).to be_a(ReceiverRespond)

        expect(model.receiver_fqname).to eq("A::B")
        expect(model.method_name).to eq("foo")
        expect(model.source).to eq("self")
      end
    end

    describe ".receivers_respond_to" do
      before do
        rows = [
          ["A", "foo", "self"],
          ["A", "bar", "self"],
          ["B", "foo", "self"],
        ]

        described_class.insert_bulk(db: db, rows: rows)
      end

      it "returns receivers that respond to all given methods" do
        method_names = ["foo", "bar"]
        result = described_class.receivers_respond_to(
          db: db,
          method_names: method_names
        )

        expect(result).to contain_exactly("A")
      end
    end
  end
end
