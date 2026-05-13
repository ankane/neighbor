class SqlitevecRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "sqlite3", database: ":memory:"
end

Neighbor::SQLite.initialize!

SqlitevecRecord.connection.instance_eval do
  create_table :items, force: true do |t|
    t.binary :embedding
    t.binary :int8_embedding
    t.binary :binary_embedding
  end

  if ActiveRecord::VERSION::MAJOR >= 8
    create_virtual_table :virtual_items, :vec0, [
      "id integer PRIMARY KEY AUTOINCREMENT NOT NULL",
      "embedding float[3] distance_metric=L2"
    ]
  else
    execute <<~SQL
      CREATE VIRTUAL TABLE virtual_items USING vec0(
        id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
        embedding float[3] distance_metric=L2
      )
    SQL
  end

  if ActiveRecord::VERSION::MAJOR >= 8
    create_virtual_table :cosine_items, :vec0, [
      "id integer PRIMARY KEY AUTOINCREMENT NOT NULL",
      "embedding float[3] distance_metric=cosine"
    ]
  else
    execute <<~SQL
      CREATE VIRTUAL TABLE cosine_items USING vec0(
        id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
        embedding float[3] distance_metric=cosine
      )
    SQL
  end
end

class SqlitevecItem < SqlitevecRecord
  has_neighbors :embedding, dimensions: 3
  has_neighbors :int8_embedding, dimensions: 3, type: :int8
  has_neighbors :binary_embedding, dimensions: 8, type: :bit
  self.table_name = "items"
end

class SqlitevecVirtualItem < SqlitevecRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "virtual_items"
end

class SqlitevecCosineItem < SqlitevecRecord
  has_neighbors :embedding, dimensions: 3
  self.table_name = "cosine_items"
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if SqlitevecItem.send(:schema_loaded?)
