module Neighbor
  module Type
    class Sparsevec < ActiveRecord::Type::Value
      def type
        :sparsevec
      end

      def serialize(value)
        if value.is_a?(SparseVector)
          value = "{#{value.indices.zip(value.values).map { |i, v| "#{i + 1}:#{v}" }.join(",")}}/#{value.dimensions}"
        end
        super(value)
      end

      private

      def cast_value(value)
        if value.is_a?(SparseVector)
          value
        elsif value.is_a?(String)
          elements, dimensions = value.split("/")
          indices = []
          values = []
          elements[1..-2].split(",").each do |e|
            i, v = e.split(":")
            indices << i.to_i - 1
            values << v.to_f
          end
          SparseVector.new(dimensions.to_i, indices, values)
        elsif value.is_a?(Array)
          value = SparseVector.from_dense(value)
        else
          raise "can't cast #{value.class.name} to sparsevec"
        end
      end
    end
  end
end
