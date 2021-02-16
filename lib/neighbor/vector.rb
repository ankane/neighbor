module Neighbor
  class Vector < ActiveRecord::Type::Value
    def initialize(dimensions:, distance:)
      super()
      @dimensions = dimensions
      @distance = distance
    end

    def cast(value)
      return if value.nil?

      value = value.to_a.map(&:to_f)
      raise Error, "Expected #{@dimensions} dimensions, not #{value.size}" unless value.size == @dimensions

      if @distance == "cosine"
        norm = 0.0
        value.each do |v|
          norm += v * v
        end
        norm = Math.sqrt(norm)
        value.map { |v| v / norm }
      else
        value
      end
    end

    def serialize(value)
      "(#{cast(value).join(", ")})" unless value.nil?
    end

    def deserialize(value)
      value[1..-1].split(",").map(&:to_f) unless value.nil?
    end
  end
end
