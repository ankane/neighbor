module Neighbor
  module Model
    def has_neighbors(*attribute_names, dimensions: nil, normalize: nil)
      if attribute_names.empty?
        warn "[neighbor] has_neighbors without an attribute name is deprecated"
        attribute_names << :neighbor_vector
      else
        attribute_names.map!(&:to_sym)
      end

      class_eval do
        @neighbor_attributes ||= {}

        if @neighbor_attributes.empty?
          def self.neighbor_attributes
            parent_attributes =
              if superclass.respond_to?(:neighbor_attributes)
                superclass.neighbor_attributes
              else
                {}
              end

            parent_attributes.merge(@neighbor_attributes || {})
          end
        end

        attribute_names.each do |attribute_name|
          raise Error, "has_neighbors already called for #{attribute_name.inspect}" if neighbor_attributes[attribute_name]
          @neighbor_attributes[attribute_name] = {dimensions: dimensions, normalize: normalize}

          attribute attribute_name, Neighbor::Vector.new(dimensions: dimensions, normalize: normalize, model: self, attribute_name: attribute_name)
        end

        return if @neighbor_attributes.size != attribute_names.size

        scope :nearest_neighbors, ->(attribute_name, vector = nil, options = nil) {
          # cannot use keyword arguments with scope with Ruby 3.2 and Active Record 6.1
          # https://github.com/rails/rails/issues/46934
          if options.nil? && vector.is_a?(Hash)
            options = vector
            vector = nil
          end
          raise ArgumentError, "missing keyword: :distance" unless options.is_a?(Hash) && options.key?(:distance)
          distance = options.delete(:distance)
          raise ArgumentError, "unknown keywords: #{options.keys.map(&:inspect).join(", ")}" if options.any?

          if vector.nil? && !attribute_name.nil? && attribute_name.respond_to?(:to_a)
            warn "[neighbor] nearest_neighbors without an attribute name is deprecated"
            vector = attribute_name
            attribute_name = :neighbor_vector
          end
          attribute_name = attribute_name.to_sym

          options = neighbor_attributes[attribute_name]
          raise ArgumentError, "Invalid attribute" unless options
          normalize = options[:normalize]
          dimensions = options[:dimensions]

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
              connection.quote("(#{vector.map(&:to_f).join(", ")})")
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
          select_columns = select_values.any? ? [] : column_names
          select(*select_columns, "#{neighbor_distance} AS neighbor_distance")
            .where.not(attribute_name => nil)
            .order(Arel.sql(order))
        }

        def nearest_neighbors(attribute_name = nil, **options)
          if attribute_name.nil?
            warn "[neighbor] nearest_neighbors without an attribute name is deprecated"
            attribute_name = :neighbor_vector
          end
          attribute_name = attribute_name.to_sym
          # important! check if neighbor attribute before accessing
          raise ArgumentError, "Invalid attribute" unless self.class.neighbor_attributes[attribute_name]

          self.class
            .where.not(self.class.primary_key => self[self.class.primary_key])
            .nearest_neighbors(attribute_name, self[attribute_name], **options)
        end
      end
    end
  end
end
