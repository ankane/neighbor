module Neighbor
  class SparseVector
    attr_reader :dimensions, :indices, :values

    def initialize(dimensions, indices, values)
      @dimensions = dimensions
      @indices = indices
      @values = values
    end
  end
end
