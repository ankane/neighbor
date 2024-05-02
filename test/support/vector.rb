ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :items, force: true do |t|
    t.vector :embedding, limit: 3
    t.vector :factors, limit: 3
    t.halfvec :half_embedding, limit: 3
    t.bit :binary_embedding, limit: 3
  end
end

class Item < ActiveRecord::Base
  has_neighbors :embedding, :half_embedding, :binary_embedding
end

class CosineItem < ActiveRecord::Base
  has_neighbors :embedding, :half_embedding
  self.table_name = "items"
end

class DimensionsItem < ActiveRecord::Base
  has_neighbors :embedding, dimensions: 3
  self.table_name = "items"
end

class LargeDimensionsItem < ActiveRecord::Base
  has_neighbors :embedding, dimensions: 16001
  self.table_name = "items"
end
