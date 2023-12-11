module Neighbor
  module Type
    class Vector < ActiveRecord::Type::String
      def type
        :vector
      end
    end
  end
end
