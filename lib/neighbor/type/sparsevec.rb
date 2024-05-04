module Neighbor
  module Type
    class Sparsevec < ActiveRecord::Type::Value
      def type
        :sparsevec
      end

      def cast(value)
        if value.is_a?(Array)
          value = SparseVector.from_dense(value)
        end
        if value.is_a?(SparseVector)
          value = "{#{value.indices.zip(value.values).map { |i, v| "#{i + 1}:#{v}" }.join(",")}}/#{value.dimensions}"
        end
        super(value)
      end

      def deserialize(value)
        value = super
        unless value.nil?
          elements, dimensions = value.split("/")
          indices = []
          values = []
          elements[1..-2].split(",").each do |e|
            i, v = e.split(":")
            indices << i.to_i - 1
            values << v.to_f
          end
          SparseVector.new(dimensions.to_i, indices, values)
        end
      end
    end
  end
end
