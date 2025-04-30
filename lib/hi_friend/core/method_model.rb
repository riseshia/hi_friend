module HiFriend::Core
  # XXX: Rename to Method
  class MethodModel
    class << self
      def where(db:, receiver_id: nil, visibility: nil, name: nil)
        where_clauses = []
        where_clauses << "receiver_id = #{receiver_id}" if receiver_id
        where_clauses << "visibility = '#{visibility}'" if visibility
        where_clauses << "name = '#{name}'" if name
        where_clause = where_clauses.empty? ? "" : "WHERE #{where_clauses.join(' AND ')}"

        rows = db.execute(<<~SQL)
          SELECT id, receiver_id, visibility, name,
                 file_path, line
          FROM methods
          #{where_clause}
        SQL

        rows.map { |row| from_row(row) }
      end

      def insert_bulk(db:, rows:)
        return if rows.empty?

        values = rows.map do |row|
          receiver_id, visibility, name, file_path, line = row
          <<~SQL
           (#{receiver_id}, '#{visibility}', '#{name}', '#{file_path}', '#{line}')
          SQL
        end

        db.execute(<<~SQL)
          INSERT INTO methods (
            receiver_id, visibility, name,
            file_path, line
          ) VALUES
          #{values.join(",\n")}
        SQL
      end

      def insert(
        db:, receiver_id:, visibility:, name:,
        file_path:, line:
      )
        db.execute(<<~SQL)
          INSERT INTO methods (
            receiver_id, visibility, name,
            file_path, line
          ) VALUES (
            #{receiver_id}, '#{visibility}', '#{name}',
            '#{file_path}', '#{line}'
          )
        SQL
      end

      def change_visibility(db:, receiver_id:, name:, visibility:)
        db.execute(<<~SQL)
          UPDATE methods SET visibility = '#{visibility}'
          WHERE receiver_id = #{receiver_id} AND name = '#{name}'
        SQL
      end

      def from_row(row)
        new(*row)
      end
    end

    attr_reader :id, :receiver_id, :visibility, :name,
                :file_path, :line

    def initialize(
      id,
      receiver_id,
      visibility,
      name,
      file_path,
      line
    )
      @id = id
      @receiver_id = receiver_id
      @visibility = visibility
      @name = name
      @file_path = file_path
      @line = line
    end
  end
end
