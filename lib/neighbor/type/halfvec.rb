module Neighbor
  module Type
    class Halfvec < ActiveRecord::Type::Value
      def type
        :halfvec
      end

      def serialize(value)
        if value.is_a?(Array)
          value = "[#{value.join(",")}]"
        end
        super(value)
      end

      def deserialize(value)
        value = super
        value[1..-1].split(",").map(&:to_f) unless value.nil?
      end
    end
  end
end
