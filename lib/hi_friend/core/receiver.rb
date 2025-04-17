module HiFriend::Core
  class Receiver
    class << self
      def find_by_fqname(db, fqname)
        rows = db.execute(<<~SQL)
          SELECT id, full_qualified_name, name, is_singleton, file_path, line, file_hash
          FROM receivers
          WHERE full_qualified_name = '#{fqname}'
          LIMIT 1
        SQL

        return nil if rows.empty?

        from_row(rows.first)
      end

      def insert_class(
        db:, full_qualified_name:, name:,
        file_path:, line:, file_hash:
      )
        db.execute(<<~SQL)
          INSERT INTO receivers (
            full_qualified_name, name,
            is_singleton, file_path, line, file_hash
          ) VALUES (
            '#{full_qualified_name}', '#{name}',
            false, '#{file_path}', '#{line}', '#{file_hash}'
          ), (
            'singleton(#{full_qualified_name})', 'singleton(#{name})',
            true, '#{file_path}', '#{line}', '#{file_hash}'
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
      @is_singleton = is_singleton
      @file_path = file_path
      @line = line
      @file_hash = file_hash
    end
  end
end
