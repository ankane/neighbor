module Neighbor
  module Type
    class Vector < ActiveRecord::Type::Value
      def type
        :vector
      end

      def serialize(value)
        if Utils.array?(value)
          value = "[#{value.to_a.map(&:to_f).join(",")}]"
        end
        super(value)
      end

      private

      def cast_value(value)
        if value.is_a?(String)
          value[1..-1].split(",").map(&:to_f)
        elsif Utils.array?(value)
          value.to_a
        else
          raise "can't cast #{value.class.name} to vector"
        end
      end
    end
  end
end
