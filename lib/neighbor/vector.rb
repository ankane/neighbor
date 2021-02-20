module Neighbor
  class Vector < ActiveRecord::Type::Value
    def initialize(dimensions:, distance:)
      super()
      @dimensions = dimensions
      @distance = distance
    end

    def self.cast(value, dimensions:, distance:)
      value = value.to_a.map(&:to_f)
      raise Error, "Expected #{dimensions} dimensions, not #{value.size}" unless value.size == dimensions

      if distance == "cosine"
        norm = Math.sqrt(value.sum { |v| v * v })
        value.map { |v| v / norm }
      else
        value
      end
    end

    def cast(value)
      self.class.cast(value, dimensions: @dimensions, distance: @distance) unless value.nil?
    end

    def serialize(value)
      "(#{cast(value).join(", ")})" unless value.nil?
    end

    def deserialize(value)
      value[1..-1].split(",").map(&:to_f) unless value.nil?
    end
  end
end
