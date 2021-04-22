module Neighbor
  module Model
    def has_neighbors(dimensions: nil, normalize: nil)
      # TODO make configurable
      # likely use argument
      attribute_name = :neighbor_vector

      class_eval do
        raise Error, "nearest_neighbors already defined" if method_defined?(:nearest_neighbors)

        attribute attribute_name, Neighbor::Vector.new(dimensions: dimensions, normalize: normalize, model: self, attribute_name: attribute_name)

        scope :nearest_neighbors, ->(vector, distance:) {
          return none if vector.nil?

          distance = distance.to_s

          quoted_attribute = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(attribute_name)}"

          column_info = klass.type_for_attribute(attribute_name).column_info

          operator =
            if column_info[:type] == :vector
              case distance
              when "inner_product"
                "<#>"
              when "cosine"
                "<=>"
              when "euclidean"
                "<->"
              end
            else
              case distance
              when "taxicab"
                "<#>"
              when "chebyshev"
                "<=>"
              when "euclidean", "cosine"
                "<->"
              end
            end

          raise ArgumentError, "Invalid distance: #{distance}" unless operator

          # ensure normalize set (can be true or false)
          if distance == "cosine" && column_info[:type] == :cube && normalize.nil?
            raise Neighbor::Error, "Set normalize for cosine distance with cube"
          end

          vector = Neighbor::Vector.cast(vector, dimensions: dimensions, normalize: normalize, column_info: column_info)

          # important! neighbor_vector should already be typecast
          # but use to_f as extra safeguard against SQL injection
          query =
            if column_info[:type] == :vector
              connection.quote("[#{vector.map(&:to_f).join(", ")}]")
            else
              "cube(array[#{vector.map(&:to_f).join(", ")}])"
            end

          order = "#{quoted_attribute} #{operator} #{query}"

          # https://stats.stackexchange.com/questions/146221/is-cosine-similarity-identical-to-l2-normalized-euclidean-distance
          # with normalized vectors:
          # cosine similarity = 1 - (euclidean distance)**2 / 2
          # cosine distance = 1 - cosine similarity
          # this transformation doesn't change the order, so only needed for select
          neighbor_distance =
            if column_info[:type] != :vector && distance == "cosine"
              "POWER(#{order}, 2) / 2.0"
            elsif column_info[:type] == :vector && distance == "inner_product"
              "(#{order}) * -1"
            else
              order
            end

          # for select, use column_names instead of * to account for ignored columns
          select(*column_names, "#{neighbor_distance} AS neighbor_distance")
            .where.not(attribute_name => nil)
            .order(Arel.sql(order))
        }

        define_method :nearest_neighbors do |**options|
          self.class
            .where.not(self.class.primary_key => send(self.class.primary_key))
            .nearest_neighbors(send(attribute_name), **options)
        end
      end
    end
  end
end
