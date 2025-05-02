# frozen_string_literal: true

module HiFriend::Core
  RSpec.describe ReceiverRespondPatcher do
    let(:db) { Storage.db }

    def method_names_of(receiver_fqname)
      rows = db.execute(<<~SQL)
        SELECT distinct method_name
        FROM receiver_responds
        WHERE receiver_fqname = '#{receiver_fqname}'
      SQL

      rows.map { |row| row[0] }
    end

    describe ".with" do
      let(:receiver_rows) { [] }
      let(:method_rows) { [] }
      let(:included_module_rows) { [] }
      let(:receiver_respond_rows) { [] }

      before do
        Receiver.insert_bulk(db: db, rows: receiver_rows)
        method_rows.each do |row|
          row[0] = Receiver.find_id_by(db, fqname: row[0])
        end
        MethodModel.insert_bulk(db: db, rows: method_rows)
        IncludedModule.insert_bulk(db: db, rows: included_module_rows)
        ReceiverRespond.insert_bulk(db: db, rows: receiver_respond_rows)
      end

      context "when db has no records" do
        let(:receiver_rows) do
          [
            ["Class", "A", false, "/path/to/a.rb", 10, "hash123"],
            ["Class", "singleton(A)", true, "/path/to/a.rb", 10, "hash123"],
            ["Class", "B", false, "/path/to/b.rb", 10, "hash123"],
            ["Class", "singleton(B)", true, "/path/to/b.rb", 10, "hash123"],
            ["Module", "FeatureA", false, "/path/to/feature_a.rb", 10, "hash123"],
            ["Module", "FeatureB", false, "/path/to/feature_b.rb", 10, "hash123"],
            ["Module", "FeatureC", false, "/path/to/feature_c.rb", 10, "hash123"],
            ["Module", "FeatureD", false, "/path/to/feature_d.rb", 10, "hash123"],
          ]
        end

        let(:method_rows) do
          [
            ["A", "public", "method_from_a", "/path/to/a.rb", 10],
            ["singleton(A)", "public", "method_from_singleton_a", "/path/to/a.rb", 10],
            ["B", "public", "method_from_b", "/path/to/b.rb", 10],
            ["singleton(B)", "public", "method_from_singleton_b", "/path/to/b.rb", 10],
            ["FeatureA", "public", "method_from_feature_a", "/path/to/feature_a.rb", 10],
            ["FeatureB", "public", "method_from_feature_b", "/path/to/feature_b.rb", 10],
            ["FeatureC", "public", "method_from_feature_c", "/path/to/feature_c.rb", 10],
            ["FeatureD", "public", "method_from_feature_d", "/path/to/feature_d.rb", 10],
          ]
        end

        let(:included_module_rows) do
          [
            ["inherit", "B", "Object", "A", "/path/to/b.rb", 10],
            ["inherit", "singleton(B)", "Object", "A", "/path/to/b.rb", 10],
            ["mixin", "A", "Object",  "FeatureA", "/path/to/feature_a.rb", 10],
            ["mixin", "singleton(A)", "Object", "FeatureB", "/path/to/feature_b.rb", 10],
            ["mixin", "B", "Object", "FeatureC", "/path/to/feature_c.rb", 10],
            ["mixin", "singleton(B)", "Object", "FeatureD", "/path/to/feature_d.rb", 10],
          ]
        end

        it "generates receiver_respond records" do
          paths = receiver_rows.map { |row| row[3] }

          described_class.with(db: db, file_paths: paths)

          expect(method_names_of("A")).to contain_exactly(
            "method_from_a", "method_from_feature_a"
          )
          expect(method_names_of("singleton(A)")).to contain_exactly(
            "method_from_singleton_a", "method_from_feature_b"
          )
          expect(method_names_of("B")).to contain_exactly(
            "method_from_a", "method_from_feature_a",
            "method_from_b", "method_from_feature_c"
          )
          expect(method_names_of("singleton(B)")).to contain_exactly(
            "method_from_singleton_a", "method_from_feature_b",
            "method_from_singleton_b", "method_from_feature_d"
          )
        end
      end
    end
  end
end
