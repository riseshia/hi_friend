module HiFriend::Core
  class IncludedModule
    class << self
      def where(db, kind: nil, child_fqname: nil)
        where_clauses = []
        where_clauses << "kind = '#{kind}'" if kind
        where_clauses << "child_receiver_fqname = '#{child_fqname}'" if child_fqname
        where_clause = where_clauses.empty? ? "" : "WHERE #{where_clauses.join(' AND ')}"

        rows = db.execute(<<~SQL)
          SELECT kind, child_receiver_fqname, parent_receiver_name,
                 file_path, line
          FROM included_modules
          #{where_clause}
        SQL

        rows.map { |row| from_row(row) }
      end

      def from_row(row)
        new(*row)
      end

      def insert_inherit(
        db:, child_receiver_fqname:, parent_receiver_name:,
        file_path:, line:
      )
        kind = :inherit
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            kind, child_receiver_fqname, parent_receiver_name,
            file_path, line
          ) VALUES (
            '#{kind}', '#{child_receiver_fqname}', '#{parent_receiver_name}',
            '#{file_path}', '#{line}'
          ), (
            '#{kind}', 'singleton(#{child_receiver_fqname})', '#{parent_receiver_name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end

      def insert(
        db:, kind:, child_receiver_fqname:, parent_receiver_name:,
        file_path:, line:
      )
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            kind, child_receiver_fqname, parent_receiver_name,
            file_path, line
          ) VALUES (
            '#{kind}', '#{child_receiver_fqname}', '#{parent_receiver_name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end
    end

    attr_reader :kind, :child_receiver_fqname, :parent_receiver_name,
                :file_path, :line

    def initialize(
      kind,
      child_receiver_fqname,
      parent_receiver_name,
      file_path,
      line
    )
      @kind = kind
      @child_receiver_fqname = child_receiver_fqname
      @parent_receiver_name = parent_receiver_name
      @file_path = file_path
      @line = line
    end
  end
end
