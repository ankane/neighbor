module Neighbor
  module Type
    class Vector < ActiveRecord::Type::String
      def type
        :vector
      end

      def cast(value)
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
