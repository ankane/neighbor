module Neighbor
  module Type
    class MysqlVector < ActiveRecord::Type::Binary
      def type
        :vector
      end

      def serialize(value)
        if Utils.array?(value)
          value = value.to_a.pack("e*")
        end
        super(value)
      end

      def deserialize(value)
        value = super
        cast_value(value) unless value.nil?
      end

      private

      def cast_value(value)
        if value.is_a?(String)
          value.unpack("e*")
        elsif Utils.array?(value)
          value.to_a
        else
          raise "can't cast #{value.class.name} to vector"
        end
      end
    end
  end
end
