module Neighbor
  class Vector < ActiveRecord::Type::Value
    def initialize(dimensions:, normalize:, model:, attribute_name:)
      super()
      @dimensions = dimensions
      @normalize = normalize
      @model = model
      @attribute_name = attribute_name
    end

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
      value = base_type(column_info).cast(value)

      validate_dimensions(value, column_info[:type], dimensions || column_info[:dimensions])

      if !validate_finite(value, column_info[:type])
        raise Error, "Values must be finite"
      end

      value = self.normalize(value, column_info[:type]) if normalize

      value
    end

    def self.column_info(model, attribute_name)
      column = model.columns_hash[attribute_name.to_s]
      {
        type: column.try(:type),
        dimensions: column.try(:limit)
      }
    end

    # need to be careful to avoid loading column info before needed
    def column_info
      @column_info ||= self.class.column_info(@model, @attribute_name)
    end

    def cast(value)
      self.class.cast(value, dimensions: @dimensions, normalize: @normalize, column_info: column_info) unless value.nil?
    end

    def serialize(value)
      base_type.serialize(cast(value)) unless value.nil?
    end

    def deserialize(value)
      base_type.deserialize(value) unless value.nil?
    end

    private

    def base_type
      self.class.base_type(column_info)
    end

    def self.base_type(column_info)
      case column_info[:type]
      when :vector
        Type::Vector.new
      when :halfvec
        Type::Halfvec.new
      when :sparsevec
        Type::Sparsevec.new
      when :cube
        Type::Cube.new
      when :bit
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Bit.new
      else
        raise "Unsupported type: #{column_info[:type]}"
      end
    end
  end
end
