class SqliteRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "sqlite3", database: ":memory:"
end

SqliteRecord.connection.instance_eval do
  create_table :items, force: true do |t|
    t.binary :embedding
    t.binary :int8_embedding
    t.binary :binary_embedding
  end
end

class SqliteItem < SqliteRecord
  has_neighbors :embedding, dimensions: 3
  has_neighbors :int8_embedding, dimensions: 3, type: :int8
  has_neighbors :binary_embedding, dimensions: 8, type: :bit
  self.table_name = "items"
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if SqliteItem.send(:schema_loaded?)
