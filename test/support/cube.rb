ActiveRecord::Schema.define do
  enable_extension "cube"

  create_table :items, force: true do |t|
    t.cube :neighbor_vector
    t.cube :embedding
  end
end

class Item < ActiveRecord::Base
  has_neighbors
  has_neighbors :embedding
end

class CosineItem < ActiveRecord::Base
  has_neighbors normalize: true
  self.table_name = "items"
end

class DimensionsItem < ActiveRecord::Base
  has_neighbors dimensions: 3
  self.table_name = "items"
end

class LargeDimensionsItem < ActiveRecord::Base
  has_neighbors dimensions: 101
  self.table_name = "items"
end
