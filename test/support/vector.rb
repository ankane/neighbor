ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :items, force: true do |t|
    t.vector :neighbor_vector, limit: 3
  end
end

class Item < ActiveRecord::Base
  has_neighbors
end

class CosineItem < ActiveRecord::Base
  has_neighbors
  self.table_name = "items"
end

class DimensionsItem < ActiveRecord::Base
  has_neighbors dimensions: 3
  self.table_name = "items"
end

class LargeDimensionsItem < ActiveRecord::Base
  has_neighbors dimensions: 1025
  self.table_name = "items"
end
