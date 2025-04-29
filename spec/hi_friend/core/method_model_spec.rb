# frozen_string_literal: true

require "spec_helper"

module HiFriend::Core
  RSpec.describe MethodModel do
    let(:db) { Storage.db }
    let(:receiver_id) { 999999 }

    describe ".where" do
      before do
        db.execute(<<~SQL)
          INSERT INTO methods (
            receiver_id, visibility, name,
            file_path, line
          ) VALUES (
            '#{receiver_id}', 'public', 'hoge',
            '/path/to/file.rb', 10
          )
        SQL
      end

      context "when target exists" do
        it "returns target info" do
          method = described_class.where(db, receiver_id: receiver_id, visibility: :public, name: "hoge").first
          expect(method.name).to eq("hoge")
          expect(method.file_path).to eq("/path/to/file.rb")
          expect(method.line).to eq(10)
        end
      end

      context "when parent does not exist" do
        it "returns nil" do
          method = described_class.where(db, receiver_id: receiver_id, visibility: :public, name: "hige").first
          expect(method).to be_nil
        end
      end
    end

    describe ".insert" do
      it "executes the correct SQL query" do
        MethodModel.insert(
          db: db,
          receiver_id: receiver_id,
          visibility: :public,
          name: "hoge",
          file_path: "path/to/file.rb",
          line: 10
        )

        rows = db.execute("SELECT receiver_id, visibility, name, file_path, line FROM methods WHERE receiver_id = #{receiver_id}")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[0]).to eq(receiver_id)
        expect(row[1]).to eq("public")
        expect(row[2]).to eq("hoge")
        expect(row[3]).to eq("path/to/file.rb")
        expect(row[4]).to eq(10)
      end
    end

    describe ".change_visibility" do
      before do
        db.execute(<<~SQL)
          INSERT INTO methods (
            receiver_id, visibility, name,
            file_path, line
          ) VALUES (
            #{receiver_id}, 'public', 'hoge',
            '/path/to/file.rb', 10
          )
        SQL
      end

      it "changes target method visibility" do
        MethodModel.change_visibility(
          db: db,
          receiver_id: receiver_id,
          name: "hoge",
          visibility: :private
        )

        rows = db.execute("SELECT receiver_id, visibility, name, file_path, line FROM methods WHERE receiver_id = #{receiver_id}")
        expect(rows.size).to eq(1)

        row = rows.first
        expect(row[1]).to eq("private")
      end
    end
  end
end
