module HiFriend::Core
  class ReceiverRespond
    class << self
      def find_by(db:, receiver_fqname: nil, method_name:, source: nil)
        where_clauses = []
        where_clauses << "receiver_fqname = '#{receiver_fqname}'" if receiver_fqname
        where_clauses << "method_name = '#{method_name}'"
        where_clauses << "source = '#{source}'" if source
        where_clause = where_clauses.join(" AND ")

        rows = db.execute(<<~SQL)
          SELECT receiver_fqname, method_name, source
          FROM receiver_responds
          WHERE #{where_clause}
          LIMIT 1
        SQL

        return nil if rows.empty?

        from_row(rows.first)
      end

      def receivers_respond_to(db:, method_names:, self_only: false)
        method_num = method_names.size
        method_names_in = method_names.map { |name| "'#{name}'" }.join(", ")

        where_clauses = ["method_name IN (#{method_names_in})"]
        where_clauses << "source = 'self'" if self_only
        where_clause = where_clauses.join(" AND ")

        rows = db.execute(<<~SQL)
          SELECT receiver_fqname, count(*) as c
          FROM receiver_responds
          WHERE #{where_clause}
          GROUP BY receiver_fqname
          HAVING c = #{method_num}
        SQL

        rows.map { |r| r.first }
      end

      def insert_bulk(db:, rows:)
        return if rows.empty?

        values = rows.map do |row|
          receiver_fqname, method_name, source = row
          <<~SQL
           ('#{receiver_fqname}', '#{method_name}', '#{source}')
          SQL
        end

        db.execute(<<~SQL)
          INSERT INTO receiver_responds (
            receiver_fqname, method_name, source
          ) VALUES
          #{values.join(",\n")}
        SQL
      end

      def insert(
        db:, receiver_fqname:, method_name:, source:
      )
        db.execute(<<~SQL)
          INSERT INTO receiver_responds (
            receiver_fqname, method_name, source
          ) VALUES (
            '#{receiver_fqname}', '#{method_name}', '#{source}'
          )
        SQL
      end

      def from_row(row)
        new(*row)
      end
    end

    attr_reader :receiver_fqname, :method_name, :source

    def initialize(
      receiver_fqname, method_name, source
    )
      @receiver_fqname = receiver_fqname
      @method_name = method_name
      @source = source
    end
  end
end
