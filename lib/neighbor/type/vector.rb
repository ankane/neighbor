module Neighbor
  module Type
    class Vector < ActiveRecord::Type::Value
      def type
        :vector
      end

      def serialize(value)
        if value.is_a?(Array)
          value = "[#{value.join(",")}]"
        end
        super(value)
      end

      private

      def cast_value(value)
        if value.is_a?(String)
          value[1..-1].split(",").map(&:to_f)
        elsif value.is_a?(Array)
          value
        else
          raise "can't cast #{value.class.name} to vector"
        end
      end
    end
  end
end
