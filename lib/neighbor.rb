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

  # prevent unknown OID warning
  require "active_record/connection_adapters/postgresql_adapter"
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.prepend(Neighbor::RegisterCubeType)
end
