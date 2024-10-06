if ActiveRecord::VERSION::STRING.to_f < 7.1
  require "trilogy_adapter/connection"
  ActiveRecord::Base.public_send :extend, TrilogyAdapter::Connection
end

class MysqlRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: (ENV["TEST_TRILOGY"] ? "trilogy" : "mysql2"), database: "neighbor_test", host: "127.0.0.1", username: "root"
end

MysqlRecord.connection.instance_eval do
  create_table :mysql_items, force: true do |t|
    t.vector :embedding, limit: 3
    t.binary :binary_embedding
  end
end

class MysqlItem < MysqlRecord
  has_neighbors :embedding
  has_neighbors :binary_embedding, dimensions: 8192
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if MysqlItem.send(:schema_loaded?)
