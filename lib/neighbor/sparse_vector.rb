module Neighbor
  class SparseVector
    attr_reader :dimensions, :indices, :values

    def initialize(dimensions, indices, values)
      @dimensions = dimensions
      @indices = indices
      @values = values
    end

    def to_a
      a = Array.new(dimensions, 0.0)
      @indices.zip(@values) do |i, v|
        a[i] = v
      end
      a
    end

    def self.from_dense(a)
      a = a.to_a
      dimensions = a.size
      indices = a.filter_map.with_index { |v, i| v != 0 ? i : nil }
      values = indices.map { |i| a[i].to_f }
      SparseVector.new(dimensions, indices, values)
    end
  end
end
