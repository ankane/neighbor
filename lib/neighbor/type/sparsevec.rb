module Neighbor
  module Type
    class Sparsevec < ActiveRecord::Type::String
      def type
        :sparsevec
      end

      # TODO improve
      def deserialize(value)
        super
      end
    end
  end
end
