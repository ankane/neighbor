ActiveRecord::Schema.define do
  enable_extension "cube"

  create_table :items, force: true do |t|
    t.cube :embedding
    t.cube :neighbor_vector
    t.cube :factors
    t.bit :binary_embedding, limit: 3
  end
end

class Item < ActiveRecord::Base
  has_neighbors :embedding, :binary_embedding
  has_neighbors
end

class CosineItem < ActiveRecord::Base
  has_neighbors :embedding, normalize: true
  self.table_name = "items"
end

class DimensionsItem < ActiveRecord::Base
  has_neighbors :embedding, dimensions: 3
  self.table_name = "items"
end

class LargeDimensionsItem < ActiveRecord::Base
  has_neighbors :embedding, dimensions: 101
  self.table_name = "items"
end
