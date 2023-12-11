module Neighbor
  module Type
    class Cube < ActiveRecord::Type::String
      def type
        :cube
      end
    end
  end
end
