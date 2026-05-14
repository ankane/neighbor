module Neighbor
  module SQLite
    class << self
      attr_reader :extensions
    end

    # note: this is a public API (unlike PostgreSQL and MySQL)
    def self.initialize!(extension: :sqlite_vec)
      if extension == :sqlite_vec
        require "sqlite_vec"
      elsif !extension.is_a?(String)
        raise ArgumentError, "Unsupported extension"
      end

      (@extensions ||= []) << extension
    end

    def self.initialize_adapter!
      @extensions ||= []

      require_relative "type/sqlite_vector"
      require_relative "type/sqlite_int8_vector"

      require "active_record/connection_adapters/sqlite3_adapter"
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend(InstanceMethods)
    end

    def self.vec1?
      extensions.any?(String)
    end

    def self.sqlite_vec?
      extensions.include?(:sqlite_vec)
    end

    def self.setup_functions(db)
      db.create_function("neighbor_l2_distance", 2) do |func, a, b, c|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            raise SQLite3::SQLException, "different vector dimensions" if a.bytesize != b.bytesize
            fmt = c == 1 ? "c*" : "f*"
            a = a.unpack(fmt)
            b = b.unpack(fmt)
            Math.sqrt(a.zip(b).sum { |ai, bi| (ai - bi)**2 })
          end
      end

      db.create_function("neighbor_max_inner_product", 2) do |func, a, b, c|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            raise SQLite3::SQLException, "different vector dimensions" if a.bytesize != b.bytesize
            fmt = c == 1 ? "c*" : "f*"
            a = a.unpack(fmt)
            b = b.unpack(fmt)
            -a.zip(b).sum { |ai, bi| ai * bi }
          end
      end

      db.create_function("neighbor_cosine_distance", 2) do |func, a, b, c|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            raise SQLite3::SQLException, "different vector dimensions" if a.bytesize != b.bytesize
            fmt = c == 1 ? "c*" : "f*"
            a = a.unpack(fmt)
            b = b.unpack(fmt)
            similarity = a.zip(b).sum { |ai, bi| ai * bi }
            norma = a.sum { |v| v * v }
            normb = b.sum { |v| v * v }
            1.0 - (similarity / Math.sqrt(norma * normb)).clamp(-1.0, 1.0)
          end
      end

      db.create_function("neighbor_l1_distance", 2) do |func, a, b, c|
        func.result =
          if a.nil? || b.nil?
            nil
          else
            raise SQLite3::SQLException, "different vector dimensions" if a.bytesize != b.bytesize
            fmt = c == 1 ? "c*" : "f*"
            a = a.unpack(fmt)
            b = b.unpack(fmt)
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
        SQLite.setup_functions(db)
        if SQLite.extensions.any?
          db.enable_load_extension(1)
          begin
            SQLite.extensions.each do |extension|
              if extension == :sqlite_vec
                SqliteVec.load(db)
              else
                db.load_extension(extension)
              end
            end
          ensure
            db.enable_load_extension(0)
          end
        end
      end
    end
  end
end
