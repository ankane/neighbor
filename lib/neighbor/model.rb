module Neighbor
  module Helpers
    class << self
      # Determines the operator for the distance function.
      def determine_operator(distance, is_vector)
        if is_vector
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
      end
      # https://stats.stackexchange.com/questions/146221/is-cosine-similarity-identical-to-l2-normalized-euclidean-distance
      # with normalized vectors:
      # cosine similarity = 1 - (euclidean distance)**2 / 2
      # cosine distance = 1 - cosine similarity
      # this transformation doesn't change the order, so only needed for select
      def neighbor_distance_statement(distance, order, is_vector)
        if !is_vector && distance == "cosine"
          "POWER(#{order}, 2) / 2.0"
        elsif is_vector && distance == "inner_product"
          "(#{order}) * -1"
        else
          order
        end
      end
      # Opts key must be lt, lte, gt, or gte and have a numeric value
      # Returns an array of strings that can be passed to ActiveRecord where method
      # Example: {lt: 5, gte: 2} => ["neighbor_distance < 5", "neighbor_distance >= 2"]
      def args_for_threshold(quoted_neighbor_field, opts)
        raise ArgumentError, "Invalid threshold" unless opts.is_a?(Hash)

        opts.map do |key, value|
          raise ArgumentError, "Invalid threshold: allowed keys are lt, lte, gt, gte" unless [:lt, :lte, :gt, :gte].include?(key)
          raise ArgumentError, "Invalid threshold: value must be numeric type" unless value.is_a?(Numeric)

          case key
          when :lt
            ["#{quoted_neighbor_field} < ?", value]
          when :lte
            ["#{quoted_neighbor_field} <= ?", value]
          when :gt
            ["#{quoted_neighbor_field} > ?", value]
          when :gte
            ["#{quoted_neighbor_field} >= ?", value]
          end
        end
      end
    end
  end

  module Model
    def has_neighbors(*attribute_names, dimensions: nil, normalize: nil)
      if attribute_names.empty?
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

        scope :nearest_neighbors, ->(attribute_name, vector = nil, distance:, **kwargs) {
          # Check optional arguments for threshold
          if vector.nil? && !attribute_name.nil? && attribute_name.respond_to?(:to_a)
            vector = attribute_name
            attribute_name = :neighbor_vector
          end
          
          attribute_name = attribute_name.to_sym
          options = neighbor_attributes[attribute_name]

          raise ArgumentError, "Invalid attribute" unless options
          
          normalize = options[:normalize]
          dimensions = options[:dimensions]

          # Check optional arguments in options
          order_option = kwargs[:order] || nil
          limit_option = kwargs[:limit] || nil
          threshold_option = kwargs[:threshold] || nil

          return none if vector.nil?

          distance = distance.to_s

          # Define the quoted attribute names
          quoted_attribute = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name(attribute_name)}"
          quoted_neighbor = "#{connection.quote_table_name(table_name)}.#{connection.quote_column_name('neighbor_distance')}"

          column_info = klass.type_for_attribute(attribute_name).column_info

          # Check if column type is vector or cube
          is_cube = column_info[:type] == :cube
          is_vector = column_info[:type] == :vector

          operator = Neighbor::Helpers.determine_operator(distance, is_vector)

          raise ArgumentError, "Invalid distance: #{distance}" unless operator

          # ensure normalize set (can be true or false)
          if distance == "cosine" && is_cube && normalize.nil?
            raise Neighbor::Error, "Set normalize for cosine distance with cube"
          end

          vector = Neighbor::Vector.cast(vector, dimensions: dimensions, normalize: normalize, column_info: column_info)

          # important! neighbor_vector should already be typecast
          # but use to_f as extra safeguard against SQL injection
          query = is_vector ? connection.quote("[#{vector.map(&:to_f).join(", ")}]") : "cube(array[#{vector.map(&:to_f).join(", ")}])"

          order = "#{quoted_attribute} #{operator} #{query}"

          neighbor_distance = Neighbor::Helpers.neighbor_distance_statement(distance, order, is_vector)
          
          # Add ActiveRecord methods to options_chain if they are present in options
          options_chain = []
          options_chain << [:limit, limit_option] if limit_option
          options_chain << [:reorder, order_option] if order_option

          # for select, use column_names instead of * to account for ignored columns
          select_query = select(*column_names, "#{neighbor_distance} AS neighbor_distance")
            .where.not(attribute_name => nil)
            .order(Arel.sql(order))

          # Add threshold query to select query if threshold option is present
          if threshold_option
            select_query = from(select_query, table_name.to_sym).where(
              *Neighbor::Helpers.args_for_threshold(quoted_neighbor, threshold_option)
            )
          end

          # Run through all options and apply them to the select query
          options_chain.inject(select_query) do |obj, method_and_args| 
            obj.send(*method_and_args)
          end
        }

        def nearest_neighbors(attribute_name = :neighbor_vector, **options)
          attribute_name = attribute_name.to_sym
          # important! check if neighbor attribute before calling send
          raise ArgumentError, "Invalid attribute" unless self.class.neighbor_attributes[attribute_name]

          self.class
            .where.not(self.class.primary_key => self[self.class.primary_key])
            .nearest_neighbors(attribute_name, self[attribute_name], **options)
        end
      end
    end
  end
end
