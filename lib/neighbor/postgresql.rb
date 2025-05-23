module Neighbor
  module PostgreSQL
    def self.initialize!
      require_relative "type/cube"
      require_relative "type/halfvec"
      require_relative "type/sparsevec"
      require_relative "type/vector"

      require "active_record/connection_adapters/postgresql_adapter"

      # ensure schema can be dumped
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:cube] = {name: "cube"}
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:halfvec] = {name: "halfvec"}
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:sparsevec] = {name: "sparsevec"}
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

      # ensure schema can be loaded
      ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :cube, :halfvec, :sparsevec, :vector)

      # prevent unknown OID warning
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(RegisterTypes)

      # support vector[]/halfvec[]
      ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Array.prepend(ArrayMethods)
    end

    module RegisterTypes
      def initialize_type_map(m = type_map)
        super
        m.register_type "cube", Type::Cube.new
        m.register_type "halfvec" do |_, _, sql_type|
          limit = extract_limit(sql_type)
          Type::Halfvec.new(limit: limit)
        end
        m.register_type "sparsevec" do |_, _, sql_type|
          limit = extract_limit(sql_type)
          Type::Sparsevec.new(limit: limit)
        end
        m.register_type "vector" do |_, _, sql_type|
          limit = extract_limit(sql_type)
          Type::Vector.new(limit: limit)
        end
      end
    end

    ArrayWrapper = Struct.new(:to_a)

    module ArrayMethods
      def type_cast_array(value, method, ...)
        if (subtype.is_a?(Neighbor::Type::Vector) || subtype.is_a?(Neighbor::Type::Halfvec)) && method != :deserialize && value.is_a?(::Array) && value.all? { |v| v.is_a?(::Numeric) }
          super(ArrayWrapper.new(value), method, ...)
        else
          super
        end
      end
    end
  end
end
