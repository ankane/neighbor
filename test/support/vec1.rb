class Vec1Record < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "sqlite3", database: ":memory:"
end

Neighbor::SQLite.initialize!(extension: "/tmp/vec1.so")

Vec1Record.connection.instance_eval do
  create_table :items, force: true do |t|
    t.binary :embedding
  end

  if ActiveRecord::VERSION::MAJOR >= 8
    create_virtual_table :virtual_items, :vec1, ["embedding", "id"]
  else
    execute <<~SQL
      CREATE VIRTUAL TABLE virtual_items USING vec1(embedding, id)
    SQL
  end
end

class Vec1Item < Vec1Record
  has_neighbors :embedding, dimensions: 3
  self.table_name = "items"
end

class Vec1VirtualItem < Vec1Record
  has_neighbors :embedding, dimensions: 3
  self.table_name = "virtual_items"
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if Vec1Item.send(:schema_loaded?)
