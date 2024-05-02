module Neighbor
  module Type
    class Vector < ActiveRecord::Type::String
      def type
        :vector
      end

      def deserialize(value)
        value[1..-1].split(",").map(&:to_f) unless value.nil?
      end
    end
  end
end
