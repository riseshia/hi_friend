# frozen_string_literal: true

module HiFriend::Core
  RSpec.describe Receiver do
    def fetch_rows_by_fqname(fqname)
      db.execute("SELECT kind, fqname, is_singleton, file_path, line, file_hash FROM receivers WHERE fqname = '#{fqname}'")
    end

    let(:db) { Storage.db }

    describe ".find_by_fqname" do
      context "when receiver exists" do
        before do
          db.execute(<<~SQL)
            INSERT INTO receivers (
              kind, fqname,
              is_singleton, file_path, line, file_hash
            ) VALUES (
              'Class', 'Test::Class',
              'false', '/path/to/file.rb', 10, 'hash123'
            )
          SQL
        end

        it "returns a receiver instance" do
          receiver = described_class.find_by_fqname(db, "Test::Class")
          expect(receiver).to be_a(Receiver)
          expect(receiver.kind).to eq("Class")
          expect(receiver.fqname).to eq("Test::Class")
          expect(receiver.is_singleton).to eq(false)
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

    describe ".receiver_names_by_paths" do
      before do
        db.execute(<<~SQL)
          INSERT INTO receivers (
            kind, fqname, is_singleton, file_path, line, file_hash
          ) VALUES (
            'Class', 'A', 'false', '/path/to/file1.rb', 10, 'hash123'
          ), (
            'Class', 'B', 'false', '/path/to/file1.rb', 10, 'hash123'
          ), (
            'Class', 'B', 'false', '/path/to/file2.rb', 10, 'hash123'
          ), (
            'Class', 'C', 'false', '/path/to/file3.rb', 10, 'hash123'
          )
        SQL
      end

      it "returns a receiver instance" do
        paths = [
          "/path/to/file1.rb",
          "/path/to/file2.rb",
        ]

        receiver_names = described_class.receiver_names_by_paths(db: db, paths: paths)
        expect(receiver_names).to match_array(["A", "B"])
      end
    end

    describe ".insert_class" do
      it "inserts new record for class" do
        described_class.insert_class(
          db: db,
          fqname: "A::B",
          file_path: "/path/to/module.rb",
          line: 20,
          file_hash: "hash456"
        )

        rows = fetch_rows_by_fqname("A::B")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq("Class")
        expect(row[1]).to eq("A::B")
        expect(row[2]).to eq(0)
        expect(row[3]).to eq("/path/to/module.rb")
        expect(row[4]).to eq(20)
        expect(row[5]).to eq("hash456")

        rows = fetch_rows_by_fqname("singleton(A::B)")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq("Class")
        expect(row[1]).to eq("singleton(A::B)")
        expect(row[2]).to eq(1)
        expect(row[3]).to eq("/path/to/module.rb")
        expect(row[4]).to eq(20)
        expect(row[5]).to eq("hash456")
      end
    end

    describe ".insert_module" do
      it "inserts new record for module" do
        described_class.insert_module(
          db: db,
          fqname: "A::B",
          file_path: "/path/to/module.rb",
          line: 20,
          file_hash: "hash456"
        )

        rows = fetch_rows_by_fqname("A::B")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq("Module")
        expect(row[1]).to eq("A::B")
        expect(row[2]).to eq(0)
        expect(row[3]).to eq("/path/to/module.rb")
        expect(row[4]).to eq(20)
        expect(row[5]).to eq("hash456")

        rows = fetch_rows_by_fqname("singleton(A::B)")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq("Class")
        expect(row[1]).to eq("singleton(A::B)")
        expect(row[2]).to eq(1)
        expect(row[3]).to eq("/path/to/module.rb")
        expect(row[4]).to eq(20)
        expect(row[5]).to eq("hash456")
      end
    end

    describe ".insert_bulk" do
      it "inserts new records" do
        rows = [
          ["Class", "A", false, "/path/to/file1.rb", 10, "hash123"],
          ["Class", "singleton(A)", true, "/path/to/file1.rb", 10, "hash123"],
        ]

        described_class.insert_bulk(db: db, rows: rows)

        rows = fetch_rows_by_fqname("A")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row).to contain_exactly(
          "Class", "A", 0, "/path/to/file1.rb", 10, "hash123"
        )

        rows = fetch_rows_by_fqname("singleton(A)")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row).to contain_exactly(
          "Class", "singleton(A)", 1, "/path/to/file1.rb", 10, "hash123"
        )
      end
    end

    describe ".resolve_name" do
      before do
        rows = [
          ["Module", "A", false, "/path/to/a.rb", 10, "hash123"],
          ["Module", "A::B", false, "/path/to/a/b.rb", 10, "hash123"],
          ["Class", "A::B::C", false, "/path/to/a/b/c.rb", 10, "hash123"],
          ["Class", "A::C", false, "/path/to/a/c.rb", 10, "hash123"],
          ["Class", "B::C", false, "/path/to/b/c.rb", 10, "hash123"],
          ["Class", "C", false, "/path/to/c.rb", 10, "hash123"],
          ["Class", "D", false, "/path/to/d.rb", 10, "hash123"],
        ]

        described_class.insert_bulk(db: db, rows: rows)
      end

      it "return nil" do
        resolved_name = described_class.resolve_name(db: db, eval_scope: "Object", name: "NotFound")
        expect(resolved_name).to be_nil

        resolved_name = described_class.resolve_name(db: db, eval_scope: "A::B::C", name: "NotFound")
        expect(resolved_name).to be_nil
      end

      it "return name in root" do
        resolved_name = described_class.resolve_name(db: db, eval_scope: "Object", name: "C")
        expect(resolved_name).to eq("C")

        resolved_name = described_class.resolve_name(db: db, eval_scope: "A::B", name: "D")
        expect(resolved_name).to eq("D")
      end

      it "return name in parent module" do
        resolved_name = described_class.resolve_name(db: db, eval_scope: "A", name: "B::C")
        expect(resolved_name).to eq("A::B::C")
      end

      it "return name in same module" do
        resolved_name = described_class.resolve_name(db: db, eval_scope: "A::B", name: "C")
        expect(resolved_name).to eq("A::B::C")

        resolved_name = described_class.resolve_name(db: db, eval_scope: "A", name: "C")
        expect(resolved_name).to eq("A::C")
      end
    end
  end
end
