module Neighbor
  module Type
    class Halfvec < ActiveRecord::Type::String
      def type
        :halfvec
      end

      def deserialize(value)
        value[1..-1].split(",").map(&:to_f) unless value.nil?
      end
    end
  end
end
