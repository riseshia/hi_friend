require "sqlite3"

module HiFriend::Core
  class Storage
    def self.db
      @db ||= new
    end

    def initialize
      @db = SQLite3::Database.new(":memory:")
      schema_path = File.expand_path("#{__dir__}/../../../db/schema.sql")
      schema_sql = File.read(schema_path)
      @db.execute_batch(schema_sql)
    end

    def execute(query)
      @db.execute(query)
    end

    def transaction(&block)
      @db.transaction(&block)
    end

    def rollback
      @db.rollback
    end
  end
end
