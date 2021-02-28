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
      raise Error, "Values must be finite" unless value.all?(&:finite?)

      if distance == "cosine"
        norm = Math.sqrt(value.sum { |v| v * v })

        # store zero vector as all zeros
        # since NaN makes the distance always 0
        # could also throw error

        # safe to update in-place since earlier map dups
        value.map! { |v| v / norm } if norm > 0
      end

      value
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
