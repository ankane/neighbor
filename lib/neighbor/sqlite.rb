module Neighbor
  module SQLite
    def self.initialize!
      return if defined?(@initialized)

      require_relative "type/sqlite_vector"
      require_relative "type/sqlite_int8_vector"

      require "sqlite_vec"
      require "active_record/connection_adapters/sqlite3_adapter"

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(InstanceMethods)

      @initialized = true
    end

    module InstanceMethods
      def configure_connection
        super
        db = ActiveRecord::VERSION::STRING.to_f >= 7.1 ? @raw_connection : @connection
        db.enable_load_extension(1)
        SqliteVec.load(db)
        db.enable_load_extension(0)
      end
    end
  end
end
