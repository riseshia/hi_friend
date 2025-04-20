# frozen_string_literal: true

require "spec_helper"

module HiFriend::Core
  RSpec.describe Inheritance do
    let(:db) { Storage.new }

    describe ".find_by_child_fqname" do
      before do
        db.execute(<<~SQL)
          INSERT INTO inheritances (
            child_receiver_full_qualified_name, parent_receiver_name, file_path, line
          ) VALUES (
            'B', 'A',
            '/path/to/file.rb', 10
          )
        SQL
      end

      context "when parent exists" do
        it "returns parent name" do
          inheritance = described_class.find_by_child_fqname(db, "B")
          expect(inheritance.parent_receiver_name).to eq("A")
          expect(inheritance.file_path).to eq("/path/to/file.rb")
          expect(inheritance.line).to eq(10)
        end
      end

      context "when parent does not exist" do
        it "returns nil" do
          inheritance = described_class.find_by_child_fqname(db, "C")
          expect(inheritance).to be_nil
        end
      end
    end

    describe ".insert" do
      it "executes the correct SQL query" do
        Inheritance.insert(
          db: db,
          child_receiver_fqname: "B",
          parent_receiver_name: "A",
          file_path: "path/to/file.rb",
          line: 10
        )

        rows = db.execute("SELECT child_receiver_full_qualified_name, parent_receiver_name, file_path, line FROM inheritances WHERE child_receiver_full_qualified_name = 'B'")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq("B")
        expect(row[1]).to eq("A")
        expect(row[2]).to eq("path/to/file.rb")
        expect(row[3]).to eq(10)
      end
    end
  end
end
