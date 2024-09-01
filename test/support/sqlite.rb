require "sqlite_vec"

class SqliteRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "sqlite3", database: ":memory:"
end

Neighbor::SQLite.initialize!

SqliteRecord.connection.instance_eval do
  if ActiveRecord::VERSION::MAJOR >= 8
    create_virtual_table :items, :vec0, ["id integer PRIMARY KEY AUTOINCREMENT NOT NULL", "embedding float[3]"]
  else
    execute "CREATE VIRTUAL TABLE items USING vec0(id integer PRIMARY KEY AUTOINCREMENT NOT NULL, embedding float[3])"
  end
end

class SqliteItem < SqliteRecord
  has_neighbors :embedding
  self.table_name = "items"

  # TODO move to has_neighbors
  attribute :embedding, Neighbor::Type::SqliteVector.new
end
