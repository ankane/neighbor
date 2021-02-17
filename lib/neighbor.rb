# dependencies
require "active_support"

# modules
require "neighbor/version"

module Neighbor
  class Error < StandardError; end

  module RegisterCubeType
    def initialize_type_map(m = type_map)
      super
      m.register_type "cube", ActiveRecord::ConnectionAdapters::PostgreSQL::OID::SpecializedString.new(:cube)
    end
  end
end

ActiveSupport.on_load(:active_record) do
  require "neighbor/model"
  require "neighbor/vector"

  extend Neighbor::Model

  require "active_record/connection_adapters/postgresql_adapter"

  # ensure schema can be dumped
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:cube] = {name: "cube"}

  # ensure schema can be loaded
  if ActiveRecord::VERSION::MAJOR >= 6
    ActiveRecord::ConnectionAdapters::TableDefinition.send(:define_column_methods, :cube)
  else
    ActiveRecord::ConnectionAdapters::TableDefinition.define_method :cube do |*args, **options|
      args.each { |name| column(name, :cube, options) }
    end
  end

  # prevent unknown OID warning
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Neighbor::RegisterCubeType)
end
