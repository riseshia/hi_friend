module HiFriend::Core
  class IncludedModule
    class << self
      def where(db:, kind: nil, target_fqname: nil)
        where_clauses = []
        where_clauses << "kind = '#{kind}'" if kind
        if target_fqname
          if target_fqname.is_a?(Array) && target_fqname.size > 0
            target_fqname = target_fqname.map { |n| "'#{n}'" }.join(", ")
            where_clauses << "target_fqname IN (#{target_fqname})"
          else
            where_clauses << "target_fqname = '#{target_fqname}'"
          end
        end
        where_clause = where_clauses.empty? ? "" : "WHERE #{where_clauses.join(' AND ')}"

        rows = db.execute(<<~SQL)
          SELECT kind, target_fqname, eval_scope, passed_name,
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
        db:, target_fqname:, eval_scope:, passed_name:,
        file_path:, line:
      )
        kind = :inherit
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            kind, target_fqname, eval_scope, passed_name,
            file_path, line
          ) VALUES (
            '#{kind}', '#{target_fqname}', '#{eval_scope}', '#{passed_name}',
            '#{file_path}', '#{line}'
          ), (
            '#{kind}', 'singleton(#{target_fqname})', '#{eval_scope}', '#{passed_name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end

      def insert(
        db:, kind:, target_fqname:, eval_scope:, passed_name:,
        file_path:, line:
      )
        db.execute(<<~SQL)
          INSERT INTO included_modules (
            kind, target_fqname, eval_scope, passed_name,
            file_path, line
          ) VALUES (
            '#{kind}', '#{target_fqname}', '#{eval_scope}', '#{passed_name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end

      def insert_bulk(db:, rows:)
        return if rows.empty?

        values = rows.map do |row|
          kind, target_fqname, eval_scope, passed_name, file_path, line = row
          <<~SQL
           ('#{kind}', '#{target_fqname}', '#{eval_scope}', '#{passed_name}', '#{file_path}', #{line})
          SQL
        end

        db.execute(<<~SQL)
          INSERT INTO included_modules (
            kind, target_fqname, eval_scope, passed_name, file_path, line
          ) VALUES
          #{values.join(",\n")}
        SQL
      end
    end

    attr_reader :kind, :target_fqname, :eval_scope, :passed_name,
                :file_path, :line

    def initialize(
      kind,
      target_fqname,
      eval_scope,
      passed_name,
      file_path,
      line
    )
      @kind = kind
      @target_fqname = target_fqname
      @eval_scope = eval_scope
      @passed_name = passed_name
      @file_path = file_path
      @line = line
    end
  end
end
