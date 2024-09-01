# dependencies
require "active_support"

# modules
require_relative "neighbor/reranking"
require_relative "neighbor/sparse_vector"
require_relative "neighbor/sqlite"
require_relative "neighbor/utils"
require_relative "neighbor/version"

module Neighbor
  class Error < StandardError; end

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

  module MysqlRegisterTypes
    def initialize_type_map(m)
      super
      m.register_type %r(vector)i do |sql_type|
        limit = extract_limit(sql_type)
        Type::MysqlVector.new(limit: limit)
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require_relative "neighbor/model"
  require_relative "neighbor/type/cube"
  require_relative "neighbor/type/halfvec"
  require_relative "neighbor/type/mysql_vector"
  require_relative "neighbor/type/sparsevec"
  require_relative "neighbor/type/sqlite_vector"
  require_relative "neighbor/type/vector"

  extend Neighbor::Model

  begin
    require "active_record/connection_adapters/postgresql_adapter"
  rescue Gem::LoadError
  end

  if defined?(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter)
    # ensure schema can be dumped
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:cube] = {name: "cube"}
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:halfvec] = {name: "halfvec"}
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:sparsevec] = {name: "sparsevec"}
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

    # ensure schema can be loaded
    ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :cube, :halfvec, :sparsevec, :vector)

    # prevent unknown OID warning
    if ActiveRecord::VERSION::MAJOR >= 7
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(Neighbor::RegisterTypes)
    else
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Neighbor::RegisterTypes)
    end
  end

  require "active_record/connection_adapters/abstract_mysql_adapter"

  # ensure schema can be dumped
  ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

  # ensure schema can be loaded
  unless ActiveRecord::ConnectionAdapters::TableDefinition.method_defined?(:vector)
    ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :vector)
  end

  # prevent unknown OID warning
  if ActiveRecord::VERSION::MAJOR >= 7
    ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.singleton_class.prepend(Neighbor::MysqlRegisterTypes)
  else
    ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend(Neighbor::MysqlRegisterTypes)
  end
end

require_relative "neighbor/railtie" if defined?(Rails::Railtie)
