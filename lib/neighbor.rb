# dependencies
require "active_support"

# modules
require_relative "neighbor/postgresql"
require_relative "neighbor/reranking"
require_relative "neighbor/sparse_vector"
require_relative "neighbor/sqlite"
require_relative "neighbor/utils"
require_relative "neighbor/version"

module Neighbor
  class Error < StandardError; end

  module MysqlRegisterTypes
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

ActiveSupport.on_load(:active_record) do
  require_relative "neighbor/attribute"
  require_relative "neighbor/model"
  require_relative "neighbor/normalized_attribute"
  require_relative "neighbor/type/mysql_vector"
  require_relative "neighbor/type/sqlite_vector"

  extend Neighbor::Model

  begin
    Neighbor::PostgreSQL.initialize!
  rescue Gem::LoadError
    # tries to load pg gem, which may not be available
  end

  require "active_record/connection_adapters/abstract_mysql_adapter"

  # ensure schema can be dumped
  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

  # ensure schema can be loaded
  unless ActiveRecord::ConnectionAdapters::TableDefinition.method_defined?(:vector)
    ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :vector)
  end

  # prevent unknown OID warning
  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.singleton_class.prepend(Neighbor::MysqlRegisterTypes)
  if ActiveRecord::VERSION::STRING.to_f < 7.1
    ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.register_vector_type(ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::TYPE_MAP)
  end
end

require_relative "neighbor/railtie" if defined?(Rails::Railtie)
