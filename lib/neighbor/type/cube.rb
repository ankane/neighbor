module Neighbor
  module Type
    class Cube < ActiveRecord::Type::Value
      def type
        :cube
      end

      def serialize(value)
        if Utils.array?(value)
          value = value.to_a
          if value.first.is_a?(Array)
            value = value.map { |v| serialize_point(v) }.join(", ")
          else
            value = serialize_point(value)
          end
        end
        super(value)
      end

      private

      def cast_value(value)
        if Utils.array?(value)
          value.to_a
        elsif value.is_a?(Numeric)
          [value]
        elsif value.is_a?(String)
          if value.include?("),(")
            value[1..-1].split("),(").map { |v| v.split(",").map(&:to_f) }
          else
            value[1..-1].split(",").map(&:to_f)
          end
        else
          raise "can't cast #{value.class.name} to cube"
        end
      end

      def serialize_point(value)
        "(#{value.map(&:to_f).join(", ")})"
      end
    end
  end
end
