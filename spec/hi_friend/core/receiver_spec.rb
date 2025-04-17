# frozen_string_literal: true

require "spec_helper"

module HiFriend::Core
  RSpec.describe Receiver do
    let(:db) { Storage.new }

    describe ".find_by_fqname" do
      context "when receiver exists" do
        before do
          db.execute(<<~SQL)
            INSERT INTO receivers (
              full_qualified_name, name,
              is_singleton, file_path, line, file_hash
            ) VALUES (
              'Test::Class', 'Class',
              'false', '/path/to/file.rb', 10, 'hash123'
            )
          SQL
        end

        it "returns a receiver instance" do
          receiver = described_class.find_by_fqname(db, "Test::Class")
          expect(receiver).to be_a(Receiver)
          expect(receiver.full_qualified_name).to eq("Test::Class")
          expect(receiver.name).to eq("Class")
          expect(receiver.is_singleton).to eq("false")
          expect(receiver.file_path).to eq("/path/to/file.rb")
          expect(receiver.line).to eq(10)
          expect(receiver.file_hash).to eq("hash123")
        end
      end

      context "when receiver does not exist" do
        it "returns nil" do
          receiver = described_class.find_by_fqname(db, "NonExistent")
          expect(receiver).to be_nil
        end
      end
    end

    describe ".insert" do
      it "inserts a new receiver record" do
        described_class.insert(
          db: db,
          full_qualified_name: "Test::Module",
          name: "Module",
          is_singleton: "true",
          file_path: "/path/to/module.rb",
          line: 20,
          file_hash: "hash456"
        )

        rows = db.execute("SELECT * FROM receivers WHERE full_qualified_name = 'Test::Module'")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[1]).to eq("Test::Module")
        expect(row[2]).to eq("Module")
        expect(row[3]).to eq("true")
        expect(row[4]).to eq("/path/to/module.rb")
        expect(row[5]).to eq(20)
        expect(row[6]).to eq("hash456")
      end
    end
  end
end
