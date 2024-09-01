class MariadbRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "mysql2", database: "neighbor_test", host: "127.0.0.1", port: 3307, username: "root"
end

MariadbRecord.connection.instance_eval do
  create_table :mariadb_items, force: true do |t|
    t.binary :embedding, null: false
  end

  # TODO fix
  # add_index :mariadb_items, :embedding, type: :vector
end

class MariadbItem < MariadbRecord
  has_neighbors :embedding

  # TODO move to has_neighbors
  attribute :embedding, Neighbor::Type::MariadbVector.new
end

class MariadbCosineItem < MariadbRecord
  has_neighbors :embedding, normalize: true
  self.table_name = "mariadb_items"

  # TODO move to has_neighbors
  attribute :embedding, Neighbor::Type::MariadbVector.new
end
