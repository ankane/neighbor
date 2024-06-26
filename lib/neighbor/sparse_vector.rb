module Neighbor
  class SparseVector
    attr_reader :dimensions, :indices, :values

    NO_DEFAULT = Object.new

    def initialize(value, dimensions = NO_DEFAULT)
      if value.is_a?(Hash)
        if dimensions == NO_DEFAULT
          raise ArgumentError, "missing dimensions"
        end
        from_hash(value, dimensions)
      else
        unless dimensions == NO_DEFAULT
          raise ArgumentError, "extra argument"
        end
        from_array(value)
      end
    end

    def to_s
      "{#{@indices.zip(@values).map { |i, v| "#{i.to_i + 1}:#{v.to_f}" }.join(",")}}/#{@dimensions.to_i}"
    end

    def to_a
      arr = Array.new(dimensions, 0.0)
      @indices.zip(@values) do |i, v|
        arr[i] = v
      end
      arr
    end

    private

    def from_hash(data, dimensions)
      elements = data.select { |_, v| v != 0 }.sort
      @dimensions = dimensions.to_i
      @indices = elements.map { |v| v[0].to_i }
      @values = elements.map { |v| v[1].to_f }
    end

    def from_array(arr)
      arr = arr.to_a
      @dimensions = arr.size
      @indices = []
      @values = []
      arr.each_with_index do |v, i|
        if v != 0
          @indices << i
          @values << v.to_f
        end
      end
    end

    class << self
      def from_text(string)
        elements, dimensions = string.split("/", 2)
        indices = []
        values = []
        elements[1..-2].split(",").each do |e|
          index, value = e.split(":", 2)
          indices << index.to_i - 1
          values << value.to_f
        end
        from_parts(dimensions.to_i, indices, values)
      end

      private

      def from_parts(dimensions, indices, values)
        vec = allocate
        vec.instance_variable_set(:@dimensions, dimensions)
        vec.instance_variable_set(:@indices, indices)
        vec.instance_variable_set(:@values, values)
        vec
      end
    end
  end
end
