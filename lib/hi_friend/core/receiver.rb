module HiFriend::Core
  class Receiver
    class << self
      def find_by_fqname(db, fqname)
        rows = db.execute(<<~SQL)
          SELECT id, kind, fqname, is_singleton, file_path, line, file_hash
          FROM receivers
          WHERE fqname = '#{fqname}'
          LIMIT 1
        SQL

        return nil if rows.empty?

        from_row(rows.first)
      end

      def insert_class(
        db:, fqname:,
        file_path:, line:, file_hash:
      )
        insert(
          db: db, kind: :Class, fqname: fqname,
          file_path: file_path, line: line, file_hash: file_hash
        )
      end

      def insert_module(
        db:, fqname:,
        file_path:, line:, file_hash:
      )
        insert(
          db: db, kind: :Module, fqname: fqname,
          file_path: file_path, line: line, file_hash: file_hash
        )
      end

      def insert(
        db:, kind:, fqname:,
        file_path:, line:, file_hash:
      )
        db.execute(<<~SQL)
          INSERT INTO receivers (
            kind, fqname,
            is_singleton, file_path, line, file_hash
          ) VALUES (
            '#{kind}', '#{fqname}',
            false, '#{file_path}', '#{line}', '#{file_hash}'
          ), (
            'Class', 'singleton(#{fqname})',
            true, '#{file_path}', '#{line}', '#{file_hash}'
          )
        SQL
      end

      def from_row(row)
        new(*row)
      end
    end

    attr_reader :id, :kind, :fqname,
                :is_singleton, :file_path, :line, :file_hash

    def initialize(
      id,
      kind,
      fqname,
      is_singleton,
      file_path,
      line,
      file_hash
    )
      @id = id
      @kind = kind
      @fqname = fqname
      @is_singleton = is_singleton == 1
      @file_path = file_path
      @line = line
      @file_hash = file_hash
    end

    def singleton_fqname
      "singleton(#{fqname})"
    end
  end
end
