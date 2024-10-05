module Neighbor
  module MySQL
    def self.initialize!
      require_relative "type/mysql_vector"

      require "active_record/connection_adapters/abstract_mysql_adapter"

      # ensure schema can be dumped
      ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

      # ensure schema can be loaded
      unless ActiveRecord::ConnectionAdapters::TableDefinition.method_defined?(:vector)
        ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :vector)
      end

      # prevent unknown OID warning
      ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.singleton_class.prepend(RegisterTypes)
      if ActiveRecord::VERSION::STRING.to_f < 7.1
        ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.register_vector_type(ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::TYPE_MAP)
      end
    end

    module RegisterTypes
      def initialize_type_map(m)
        super
        register_vector_type(m)
      end

      def register_vector_type(m)
        m.register_type %r(^vector)i do |sql_type|
          limit = extract_limit(sql_type)
          Type::MysqlVector.new(limit: limit)
        end
      end
    end
  end
end
