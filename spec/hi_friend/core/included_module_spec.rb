# frozen_string_literal: true

require "spec_helper"

module HiFriend::Core
  RSpec.describe IncludedModule do
    let(:db) { Storage.db }

    describe ".where" do
      before do
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            kind, target_fqname, eval_scope, passed_name, file_path, line
          ) VALUES (
            'inherit', 'B', 'Object', 'A',
            '/path/to/file.rb', 10
          )
        SQL
      end

      context "when parent exists" do
        it "returns parent name" do
          included_module = described_class.where(db: db, kind: :inherit, target_fqname: "B").first
          expect(included_module.eval_scope).to eq("Object")
          expect(included_module.passed_name).to eq("A")
          expect(included_module.file_path).to eq("/path/to/file.rb")
          expect(included_module.line).to eq(10)
        end
      end

      context "when parent does not exist" do
        it "returns nil" do
          included_module = described_class.where(db: db, kind: :inherit, target_fqname: "C").first
          expect(included_module).to be_nil
        end
      end
    end

    describe ".insert" do
      it "executes the correct SQL query" do
        IncludedModule.insert(
          db: db,
          kind: :inherit,
          target_fqname: "B",
          eval_scope: "Object",
          passed_name: "A",
          file_path: "path/to/file.rb",
          line: 10
        )

        rows = db.execute("SELECT target_fqname, eval_scope, passed_name, file_path, line FROM included_modules WHERE target_fqname = 'B'")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq("B")
        expect(row[1]).to eq("Object")
        expect(row[2]).to eq("A")
        expect(row[3]).to eq("path/to/file.rb")
        expect(row[4]).to eq(10)
      end
    end
  end
end
