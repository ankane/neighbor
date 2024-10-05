# dependencies
require "active_support"

# adapter hooks
require_relative "neighbor/mysql"
require_relative "neighbor/postgresql"
require_relative "neighbor/sqlite"

# modules
require_relative "neighbor/reranking"
require_relative "neighbor/sparse_vector"
require_relative "neighbor/utils"
require_relative "neighbor/version"

module Neighbor
  class Error < StandardError; end
end

ActiveSupport.on_load(:active_record) do
  require_relative "neighbor/attribute"
  require_relative "neighbor/model"
  require_relative "neighbor/normalized_attribute"

  extend Neighbor::Model

  begin
    Neighbor::PostgreSQL.initialize!
  rescue Gem::LoadError
    # tries to load pg gem, which may not be available
  end

  Neighbor::MySQL.initialize!
end

require_relative "neighbor/railtie" if defined?(Rails::Railtie)
