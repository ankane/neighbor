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
      require_relative "type/sqlite_int8_vector" if extension.nil?

      require "sqlite_vec" if extension.nil?
      require "active_record/connection_adapters/sqlite3_adapter"

      ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(InstanceMethods)

      @extension = extension
      @initialized = true
    end

    module InstanceMethods
      def configure_connection
        super
        db = @raw_connection
        if SQLite.extension == false
          db.create_function("neighbor_l2_distance", 2) do |func, a, b|
            func.result =
              if a.nil? || b.nil?
                nil
              else
                a = a.unpack("f*")
                b = b.unpack("f*")
                raise Error, "different vector dimensions" if a.size != b.size
                Math.sqrt(a.zip(b).sum { |ai, bi| diff = ai - bi; diff * diff })
              end
          end

          db.create_function("neighbor_max_inner_product", 2) do |func, a, b|
            func.result =
              if a.nil? || b.nil?
                nil
              else
                a = a.unpack("f*")
                b = b.unpack("f*")
                raise Error, "different vector dimensions" if a.size != b.size
                -a.zip(b).sum { |ai, bi| ai * bi }
              end
          end

          db.create_function("neighbor_cosine_distance", 2) do |func, a, b|
            func.result =
              if a.nil? || b.nil?
                nil
              else
                a = a.unpack("f*")
                b = b.unpack("f*")
                raise Error, "different vector dimensions" if a.size != b.size
                similarity = a.zip(b).sum { |ai, bi| ai * bi }
                norma = a.sum { |v| v * v }
                normb = b.sum { |v| v * v }
                1.0 - (similarity / Math.sqrt(norma * normb)).clamp(-1.0, 1.0)
              end
          end

          db.create_function("neighbor_l1_distance", 2) do |func, a, b|
            func.result =
              if a.nil? || b.nil?
                nil
              else
                a = a.unpack("f*")
                b = b.unpack("f*")
                raise Error, "different vector dimensions" if a.size != b.size
                a.zip(b).sum { |ai, bi| (ai - bi).abs }
              end
          end
        else
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
end
