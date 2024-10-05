class SqliteRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "sqlite3", database: ":memory:"
end

Neighbor::SQLite.initialize!

SqliteRecord.connection.instance_eval do
  create_table :items, force: true do |t|
    t.binary :embedding
  end
end

class SqliteItem < SqliteRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "items"
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if SqliteItem.send(:schema_loaded?)
