module Neighbor
  module Model
    def has_neighbors(dimensions:, distance: "cosine")
      distance = distance.to_s
      raise ArgumentError, "Invalid distance: #{distance}" unless %w(cosine euclidean taxicab chebyshev).include?(distance)

      class_eval do
        attribute :neighbor_vector, Neighbor::Vector.new(dimensions: dimensions, distance: distance)

        define_method :nearest_neighbors do
          return self.class.none if neighbor_vector.nil?

          operator =
            case distance
            when "taxicab"
              "<#>"
            when "chebyshev"
              "<=>"
            else
              "<->"
            end

          # important! neighbor_vector should already be typecast
          # but use to_f as extra safeguard against SQL injection
          order = "neighbor_vector #{operator} cube(array[#{neighbor_vector.map(&:to_f).join(", ")}])"

          # https://stats.stackexchange.com/questions/146221/is-cosine-similarity-identical-to-l2-normalized-euclidean-distance
          # with normalized vectors:
          # cosine similarity = 1 - (euclidean distance)**2 / 2
          # cosine distance = 1 - cosine similarity
          # this transformation doesn't change the order, so only needed for select
          neighbor_distance = distance == "cosine" ? "POWER(#{order}, 2) / 2.0" : order

          # for select, use column_names instead of * to account for ignored columns
          self.class
            .select(*self.class.column_names, "#{neighbor_distance} AS neighbor_distance")
            .where.not(self.class.primary_key => send(self.class.primary_key))
            .where.not(neighbor_vector: nil)
            .order(Arel.sql(order))
        end
      end
    end
  end
end
