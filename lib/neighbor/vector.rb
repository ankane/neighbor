module Neighbor
  class Vector < ActiveRecord::Type::Value
    def initialize(dimensions:, normalize:, model:, attribute_name:)
      super()
      @dimensions = dimensions
      @normalize = normalize
      @model = model
      @attribute_name = attribute_name
    end

    def self.validate_dimensions(value, dimensions)
      raise Error, "Expected #{dimensions} dimensions, not #{value.size}" if dimensions && value.size != dimensions
    end

    def self.validate_finite(value)
      raise Error, "Values must be finite" unless value.all?(&:finite?)
    end

    def self.normalize(value)
      norm = Math.sqrt(value.sum { |v| v * v })

      # store zero vector as all zeros
      # since NaN makes the distance always 0
      # could also throw error
      norm > 0 ? value.map { |v| v / norm } : value
    end

    def self.cast(value, dimensions:, normalize:, column_info:)
      value = base_type(column_info).cast(value)

      # TODO fix
      value = value.to_a if value.is_a?(SparseVector)

      validate_dimensions(value, dimensions || column_info[:dimensions])
      validate_finite(value) if column_info[:type] != :bit

      value = self.normalize(value) if normalize

      # TODO fix
      value = base_type(column_info).cast(value) if column_info[:type] == :sparsevec

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
