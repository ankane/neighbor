ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :items, force: true do |t|
    t.vector :embedding, limit: 3
  end
end

class Item < ActiveRecord::Base
  has_neighbors :embedding
end

class CosineItem < ActiveRecord::Base
  has_neighbors :embedding
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
