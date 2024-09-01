class MysqlRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "mysql2", database: "neighbor_test", host: "127.0.0.1", username: "root"
end

MysqlRecord.connection.instance_eval do
  create_table :mysql_items, force: true do |t|
    t.vector :embedding, limit: 3
    t.binary :binary_embedding
  end
end

class MysqlItem < MysqlRecord
  has_neighbors :embedding, :binary_embedding
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if MysqlItem.send(:schema_loaded?)
