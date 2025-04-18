module Neighbor
  module Utils
    def self.validate_dimensions(value, type, expected, adapter)
      dimensions = type == :sparsevec ? value.dimensions : value.size
      dimensions *= 8 if type == :bit && [:sqlite, :mysql].include?(adapter)

      if expected && dimensions != expected
        "Expected #{expected} dimensions, not #{dimensions}"
      end
    end

    def self.validate_finite(value, type)
      case type
      when :bit, :integer
        true
      when :sparsevec
        value.values.all?(&:finite?)
      else
        value.all?(&:finite?)
      end
    end

    def self.validate(value, dimensions:, type:, adapter:)
      if (message = validate_dimensions(value, type, dimensions, adapter))
        raise Error, message
      end

      if !validate_finite(value, type)
        raise Error, "Values must be finite"
      end
    end

    def self.normalize(value, column_info:)
      return nil if value.nil?

      raise Error, "Normalize not supported for type" unless [:cube, :vector, :halfvec].include?(column_info&.type)

      norm = Math.sqrt(value.sum { |v| v * v })

      # store zero vector as all zeros
      # since NaN makes the distance always 0
      # could also throw error
      norm > 0 ? value.map { |v| v / norm } : value
    end

    def self.array?(value)
      !value.nil? && value.respond_to?(:to_a)
    end

    def self.adapter(model)
      case model.connection_db_config.adapter
      when /sqlite/i
        :sqlite
      when /mysql|trilogy/i
        model.connection_pool.with_connection { |c| c.try(:mariadb?) } ? :mariadb : :mysql
      else
        :postgresql
      end
    end

    def self.type(adapter, column_type)
      case adapter
      when :mysql
        if column_type == :binary
          :bit
        else
          column_type
        end
      else
        column_type
      end
    end

    def self.operator(adapter, column_type, distance)
      case adapter
      when :sqlite
        case distance
        when "euclidean"
          "vec_distance_L2"
        when "cosine"
          "vec_distance_cosine"
        when "taxicab"
          "vec_distance_L1"
        when "hamming"
          "vec_distance_hamming"
        end
      when :mariadb
        case column_type
        when :vector
          case distance
          when "euclidean"
            "VEC_DISTANCE_EUCLIDEAN"
          when "cosine"
            "VEC_DISTANCE_COSINE"
          end
        when :integer
          case distance
          when "hamming"
            "BIT_COUNT"
          end
        else
          raise ArgumentError, "Unsupported type: #{column_type}"
        end
      when :mysql
        case column_type
        when :vector
          case distance
          when "cosine"
            "COSINE"
          when "euclidean"
            "EUCLIDEAN"
          end
        when :binary
          case distance
          when "hamming"
            "BIT_COUNT"
          end
        else
          raise ArgumentError, "Unsupported type: #{column_type}"
        end
      else
        case column_type
        when :bit
          case distance
          when "hamming"
            "<~>"
          when "jaccard"
            "<%>"
          when "hamming2"
            "#"
          end
        when :vector, :halfvec, :sparsevec
          case distance
          when "inner_product"
            "<#>"
          when "cosine"
            "<=>"
          when "euclidean"
            "<->"
          when "taxicab"
            "<+>"
          end
        when :cube
          case distance
          when "taxicab"
            "<#>"
          when "chebyshev"
            "<=>"
          when "euclidean", "cosine"
            "<->"
          end
        else
          raise ArgumentError, "Unsupported type: #{column_type}"
        end
      end
    end

    def self.order(adapter, type, operator, quoted_attribute, query)
      case adapter
      when :sqlite
        case type
        when :int8
          "#{operator}(vec_int8(#{quoted_attribute}), vec_int8(#{query}))"
        when :bit
          "#{operator}(vec_bit(#{quoted_attribute}), vec_bit(#{query}))"
        else
          "#{operator}(#{quoted_attribute}, #{query})"
        end
      when :mariadb
        if operator == "BIT_COUNT"
          "BIT_COUNT(#{quoted_attribute} ^ #{query})"
        else
          "#{operator}(#{quoted_attribute}, #{query})"
        end
      when :mysql
        if operator == "BIT_COUNT"
          "BIT_COUNT(#{quoted_attribute} ^ #{query})"
        elsif operator == "COSINE"
          "DISTANCE(#{quoted_attribute}, #{query}, 'COSINE')"
        else
          "DISTANCE(#{quoted_attribute}, #{query}, 'EUCLIDEAN')"
        end
      else
        if operator == "#"
          "bit_count(#{quoted_attribute} # #{query})"
        else
          "#{quoted_attribute} #{operator} #{query}"
        end
      end
    end

    def self.normalize_required?(adapter, column_type)
      case adapter
      when :postgresql
        column_type == :cube
      else
        false
      end
    end
  end
end
