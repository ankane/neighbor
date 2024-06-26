module Neighbor
  module Type
    class Halfvec < ActiveRecord::Type::Value
      def type
        :halfvec
      end

      def serialize(value)
        if value.is_a?(Array)
          value = "[#{value.map(&:to_f).join(",")}]"
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
          raise "can't cast #{value.class.name} to halfvec"
        end
      end
    end
  end
end
