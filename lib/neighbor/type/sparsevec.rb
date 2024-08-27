module Neighbor
  module Type
    class Sparsevec < ActiveRecord::Type::Value
      def type
        :sparsevec
      end

      def serialize(value)
        if value.is_a?(SparseVector)
          value = "{#{value.indices.zip(value.values).map { |i, v| "#{i.to_i + 1}:#{v.to_f}" }.join(",")}}/#{value.dimensions.to_i}"
        end
        super(value)
      end

      private

      def cast_value(value)
        if value.is_a?(SparseVector)
          value
        elsif value.is_a?(String)
          SparseVector.from_text(value)
        elsif value.respond_to?(:to_a)
          value = SparseVector.new(value.to_a)
        else
          raise "can't cast #{value.class.name} to sparsevec"
        end
      end
    end
  end
end
