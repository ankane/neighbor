module Neighbor
  module Type
    class Cube < ActiveRecord::Type::String
      def type
        :cube
      end

      def cast(value)
        if value.is_a?(Array)
          if value.first.is_a?(Array)
            value = value.map { |v| cast_point(v) }.join(", ")
          else
            value = cast_point(value)
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
        else
          value
        end
      end

      private

      def cast_point(value)
        "(#{value.map(&:to_f).join(", ")})"
      end
    end
  end
end
