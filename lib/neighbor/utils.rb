module Neighbor
  module Utils
    def self.validate_dimensions(value, type, expected)
      dimensions = type == :sparsevec ? value.dimensions : value.size
      raise Error, "Expected #{expected} dimensions, not #{dimensions}" if expected && dimensions != expected
    end

    def self.validate_finite(value, type)
      case type
      when :bit
        true
      when :sparsevec
        value.values.all?(&:finite?)
      else
        value.all?(&:finite?)
      end
    end

    def self.normalize(value, type)
      raise Error, "Normalize not supported for type" unless [:cube, :vector, :halfvec].include?(type)

      norm = Math.sqrt(value.sum { |v| v * v })

      # store zero vector as all zeros
      # since NaN makes the distance always 0
      # could also throw error
      norm > 0 ? value.map { |v| v / norm } : value
    end

    def self.cast(value, dimensions:, normalize:, column_info:)
      validate_dimensions(value, column_info&.type, dimensions || column_info&.limit)

      if !validate_finite(value, column_info&.type)
        raise Error, "Values must be finite"
      end

      value = self.normalize(value, column_info&.type) if normalize

      value
    end
  end
end
