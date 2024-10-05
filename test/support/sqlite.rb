class SqliteRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "sqlite3", database: ":memory:"
end

Neighbor::SQLite.initialize!

SqliteRecord.connection.instance_eval do
  create_table :items, force: true do |t|
    t.binary :embedding
  end

  if ActiveRecord::VERSION::MAJOR >= 8
    create_virtual_table :vec_items, :vec0, ["id integer PRIMARY KEY AUTOINCREMENT NOT NULL", "embedding float[3]"]
  else
    execute "CREATE VIRTUAL TABLE vec_items USING vec0(id integer PRIMARY KEY AUTOINCREMENT NOT NULL, embedding float[3])"
  end

  if ActiveRecord::VERSION::MAJOR >= 8
    create_virtual_table :cosine_items, :vec0, ["id integer PRIMARY KEY AUTOINCREMENT NOT NULL", "embedding float[3] distance_metric=cosine"]
  else
    execute "CREATE VIRTUAL TABLE cosine_items USING vec0(id integer PRIMARY KEY AUTOINCREMENT NOT NULL, embedding float[3] distance_metric=cosine)"
  end
end

class SqliteItem < SqliteRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "items"
end

class SqliteVecItem < SqliteRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "vec_items"
end

class SqliteCosineItem < SqliteRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "cosine_items"
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if SqliteItem.send(:schema_loaded?)
