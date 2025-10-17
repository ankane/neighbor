class MariadbRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "mysql2", database: "neighbor_test", host: "127.0.0.1", port: 3307, username: "root"
end

begin
  MariadbRecord.connection.verify!
rescue => e
  abort <<~MSG
    Database connection failed: #{e.message}

    To use the Docker container, run:

    docker run -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 -e MARIADB_DATABASE=neighbor_test -p 3307:3306 mariadb:11.8

    (and wait for it to be ready)
  MSG
end

MariadbRecord.connection.instance_eval do
  create_table :mariadb_items, force: true do |t|
    t.vector :embedding, limit: 3, null: false
    t.index :embedding, type: :vector
  end

  create_table :mariadb_binary_items, force: true do |t|
    t.bigint :binary_embedding
  end
end

class MariadbItem < MariadbRecord
  has_neighbors :embedding
end

class MariadbCosineItem < MariadbRecord
  has_neighbors :embedding, normalize: true
  self.table_name = "mariadb_items"
end

class MariadbDimensionsItem < MariadbRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "mariadb_items"
end

class MariadbBinaryItem < MariadbRecord
  has_neighbors :binary_embedding
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if MariadbItem.send(:schema_loaded?)
