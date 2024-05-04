module Neighbor
  class SparseVector
    attr_reader :dimensions, :indices, :values

    def initialize(dimensions, indices, values)
      @dimensions = dimensions
      @indices = indices
      @values = values
    end

    def to_a
      a = [0.0] * dimensions
      @indices.zip(@values).each do |i, v|
        a[i] = v
      end
      a
    end
  end
end
