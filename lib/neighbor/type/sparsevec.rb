module Neighbor
  module Type
    class Sparsevec < ActiveRecord::Type::String
      def type
        :sparsevec
      end

      def deserialize(value)
        # TODO improve
        value unless value.nil?
      end
    end
  end
end
