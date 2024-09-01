module Neighbor
  module SQLite
    def self.initialize!
      require "sqlite_vec"
      require "active_record/connection_adapters/sqlite3_adapter"

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(InstanceMethods)
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
