module Neighbor
  module Model
    def has_neighbors(dimensions:, distance: "cosine")
      distance = distance.to_s
      raise ArgumentError, "Invalid distance: #{distance}" unless %w(cosine euclidean taxicab chebyshev).include?(distance)

      # TODO make configurable
      # likely use argument
      attribute_name = :neighbor_vector

      class_eval do
        attribute attribute_name, Neighbor::Vector.new(dimensions: dimensions, distance: distance)

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

          quoted_attribute = "#{self.class.connection.quote_table_name(self.class.table_name)}.#{self.class.connection.quote_column_name(attribute_name)}"

          # important! neighbor_vector should already be typecast
          # but use to_f as extra safeguard against SQL injection
          order = "#{quoted_attribute} #{operator} cube(array[#{neighbor_vector.map(&:to_f).join(", ")}])"

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
            .where.not(attribute_name => nil)
            .order(Arel.sql(order))
        end
      end
    end
  end
end
