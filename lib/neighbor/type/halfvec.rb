module Neighbor
  module Type
    class Halfvec < ActiveRecord::Type::String
      def type
        :halfvec
      end

      def cast(value)
        if value.is_a?(Array)
          "[#{value.join(",")}]"
        else
          super
        end
      end

      def deserialize(value)
        value[1..-1].split(",").map(&:to_f) unless value.nil?
      end
    end
  end
end
