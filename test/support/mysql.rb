class MysqlRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: (ENV["TEST_TRILOGY"] ? "trilogy" : "mysql2"), database: "neighbor_test", host: "127.0.0.1", username: "root"
end

begin
  MysqlRecord.connection.verify!
rescue => e
  abort <<~MSG
    Database connection failed: #{e.message}

    To use the Docker container, run:

    docker run -e MYSQL_ALLOW_EMPTY_PASSWORD=1 -e MYSQL_DATABASE=neighbor_test -p 3306:3306 mysql:9

    (and wait for it to be ready)
  MSG
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
