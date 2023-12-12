module Neighbor
  module Type
    class Cube < ActiveRecord::Type::String
      def type
        :cube
      end

      def cast(value)
        if value.is_a?(Array)
          if value.first.is_a?(Array)
            value.map { |v| cast_point(v) }.join(", ")
          else
            cast_point(value)
          end
        else
          super
        end
      end

      # TODO uncomment in 0.4.0
      # def deserialize(value)
      #   if value.nil?
      #     super
      #   elsif value.include?("),(")
      #     value[1..-1].split("),(").map { |v| v.split(",").map(&:to_f) }
      #   else
      #     value[1..-1].split(",").map(&:to_f)
      #   end
      # end

      private

      def cast_point(value)
        "(#{value.map(&:to_f).join(", ")})"
      end
    end
  end
end
