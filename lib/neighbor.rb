# dependencies
require "active_support"

# modules
require_relative "neighbor/version"

module Neighbor
  class Error < StandardError; end

  module RegisterTypes
    def initialize_type_map(m = type_map)
      super
      m.register_type "cube", ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:cube)
      m.register_type "vector" do |_, _, sql_type|
        limit = extract_limit(sql_type)
        ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:vector, limit: limit)
      end
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require_relative "neighbor/model"
  require_relative "neighbor/vector"

  extend Neighbor::Model

  require "active_record/connection_adapters/postgresql_adapter"

  # ensure schema can be dumped
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:cube] = {name: "cube"}
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:vector] = {name: "vector"}

  # ensure schema can be loaded
  ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :cube, :vector)

  # prevent unknown OID warning
  if ActiveRecord::VERSION::MAJOR >= 7
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.singleton_class.prepend(Neighbor::RegisterTypes)
  else
    ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Neighbor::RegisterTypes)
  end
end

require_relative "neighbor/railtie" if defined?(Rails::Railtie)
