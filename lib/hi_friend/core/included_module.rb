module HiFriend::Core
  class IncludedModule
    class << self
      def find_by_child_fqname(db, child_fqname)
        rows = db.execute(<<~SQL)
          SELECT child_receiver_full_qualified_name, parent_receiver_name,
                 file_path, line
          FROM included_modules
          WHERE child_receiver_full_qualified_name = '#{child_fqname}'
          LIMIT 1
        SQL

        return nil if rows.empty?

        from_row(rows[0])
      end

      def insert(
        db:,
        child_fqname:, parent_name:,
        file_path:, line:
      )
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            child_receiver_full_qualified_name, parent_receiver_name,
            file_path, line
          ) VALUES (
            '#{child_fqname}', '#{parent_name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end

      def from_row(row)
        new(*row)
      end

      def insert(
        db:, child_receiver_fqname:, parent_receiver_name:,
        file_path:, line:
      )
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            child_receiver_full_qualified_name, parent_receiver_name,
            file_path, line
          ) VALUES (
            '#{child_receiver_fqname}', '#{parent_receiver_name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end
    end

    attr_reader :child_receiver_full_qualified_name, :parent_receiver_name,
                :file_path, :line

    def initialize(
      child_receiver_full_qualified_name,
      parent_receiver_name,
      file_path,
      line
    )
      @child_receiver_full_qualified_name = child_receiver_full_qualified_name
      @parent_receiver_name = parent_receiver_name
      @file_path = file_path
      @line = line
    end
  end
end
