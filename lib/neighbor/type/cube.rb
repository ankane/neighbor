module Neighbor
  module Type
    class Cube < ActiveRecord::Type::Value
      def type
        :cube
      end

      def serialize(value)
        if value.is_a?(Array)
          if value.first.is_a?(Array)
            value = value.map { |v| serialize_point(v) }.join(", ")
          else
            value = serialize_point(value)
          end
        end
        super(value)
      end

      def deserialize(value)
        value = super
        unless value.nil?
          if value.include?("),(")
            value[1..-1].split("),(").map { |v| v.split(",").map(&:to_f) }
          else
            value[1..-1].split(",").map(&:to_f)
          end
        end
      end

      private

      def serialize_point(value)
        "(#{value.map(&:to_f).join(", ")})"
      end
    end
  end
end
