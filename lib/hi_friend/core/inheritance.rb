module HiFriend::Core
  class Inheritance
    class << self
      def find_parent_fqname_by_child_fqname(db, child_fqname)
        rows = db.execute(<<~SQL)
          SELECT parent_full_qualified_name
          FROM inheritances
          WHERE child_receiver_full_name = '#{child_fqname}'
          LIMIT 1
        SQL

        return nil if rows.empty?

        from_row(rows[0][0])
      end

      def insert(
        db:,
        child_fqname:, parent_fqname:,
        file_path:, line:
      )
        db.execute(<<~SQL)
          INSERT INTO inheritances (
            child_receiver_full_name, parent_receiver_full_name,
            file_path, line
          ) VALUES (
            '#{child_fqname}', '#{parent_fqname}',
            '#{file_path}', '#{line}'
          )
        SQL
      end

      def from_row(row)
        new(*row)
      end
    end

    attr_reader :id, :full_qualified_name, :name,
                :is_singleton, :file_path, :line, :file_hash

    def initialize(
      id,
      full_qualified_name,
      name,
      is_singleton,
      file_path,
      line,
      file_hash
    )
      @id = id
      @full_qualified_name = full_qualified_name
      @name = name
      @is_singleton = is_singleton == 1
      @file_path = file_path
      @line = line
      @file_hash = file_hash
    end
  end
end
