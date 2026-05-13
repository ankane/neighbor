module Neighbor
  module SQLite
    class << self
      attr_reader :extension
    end

    # note: this is a public API (unlike PostgreSQL and MySQL)
    def self.initialize!(extension: :sqlite_vec)
      return if extension == @extension

      raise Error, "Already initialized" if @extension

      require "sqlite_vec" if extension == :sqlite_vec

      @extension = extension
    end

    def self.initialize_adapter!
      require_relative "type/sqlite_vector"
      require_relative "type/sqlite_int8_vector"

      require "active_record/connection_adapters/sqlite3_adapter"
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(InstanceMethods)
    end

    def self.setup_functions(db)
      db.create_function("neighbor_l2_distance", 2) do |func, a, b|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            a = a.unpack("f*")
            b = b.unpack("f*")
            raise SQLite3::SQLException, "different vector dimensions" if a.size != b.size
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
            raise SQLite3::SQLException, "different vector dimensions" if a.size != b.size
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
            raise SQLite3::SQLException, "different vector dimensions" if a.size != b.size
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
            raise SQLite3::SQLException, "different vector dimensions" if a.size != b.size
            a.zip(b).sum { |ai, bi| (ai - bi).abs }
          end
      end

      db.create_function("neighbor_hamming_distance", 2) do |func, a, b|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            raise SQLite3::SQLException, "different vector dimensions" if a.bytesize != b.bytesize
            # TODO improve
            a.each_byte.zip(b.each_byte).sum { |ai, bi| (ai ^ bi).to_s(2).count("1") }
          end
      end

      db.create_function("neighbor_jaccard_distance", 2) do |func, a, b|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            raise SQLite3::SQLException, "different vector dimensions" if a.bytesize != b.bytesize
            # TODO improve
            ab = a.each_byte.zip(b.each_byte).sum { |ai, bi| (ai & bi).to_s(2).count("1") }
            aa = a.unpack1("B*").count("1")
            bb = b.unpack1("B*").count("1")
            ab == 0 ? 1.0 : 1.0 - (ab / (aa + bb - ab).to_f)
          end
      end
    end

    module InstanceMethods
      def configure_connection
        super
        db = @raw_connection
        if !SQLite.extension
          SQLite.setup_functions(db)
        else
          db.enable_load_extension(1)
          begin
            if SQLite.extension == :sqlite_vec
              SqliteVec.load(db)
            else
              db.load_extension(SQLite.extension)
            end
          ensure
            db.enable_load_extension(0)
          end
        end
      end
    end
  end
end
