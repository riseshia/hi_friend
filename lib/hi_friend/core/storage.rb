module HiFriend::Core
  class Storage
    def initialize
      @db = SQLite3::Database.new(":memory:")
      schema_path = File.expand_path("#{__dir__}/../../../db/schema.sql")
      schema_sql = File.read(schema_path)
      @db.execute(schema_sql)
    end

    def execute(query)
      @db.execute(query)
    end
  end
end
