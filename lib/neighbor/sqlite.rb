module Neighbor
  module SQLite
    class << self
      attr_reader :extension
    end

    # note: this is a public API (unlike PostgreSQL and MySQL)
    def self.initialize!(extension: nil)
      if defined?(@initialized)
        raise Error, "Already initialized" if extension != @extension
        return
      end

      require_relative "type/sqlite_vector"
      require_relative "type/sqlite_int8_vector" unless extension

      require "sqlite_vec" unless extension
      require "active_record/connection_adapters/sqlite3_adapter"

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(InstanceMethods)

      @extension = extension
      @initialized = true
    end

    module InstanceMethods
      def configure_connection
        super
        db = @raw_connection
        db.enable_load_extension(1)
        begin
          if SQLite.extension
            db.load_extension(SQLite.extension)
          else
            SqliteVec.load(db)
          end
        ensure
          db.enable_load_extension(0)
        end
      end
    end
  end
end
