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
      @global_env_loaded = false
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

    def global_env_loaded!
      @global_env_loaded = true
    end

    def global_env_loaded?
      @global_env_loaded
    end
  end
end
