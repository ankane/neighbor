class PostgresRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "postgresql", database: "neighbor_test"
end

PostgresRecord.connection.instance_eval do
  enable_extension "cube"
  enable_extension "vector"

  create_table :items, force: true do |t|
    t.cube :cube_embedding
    t.cube :cube_factors
    t.vector :embedding, limit: 3
    t.vector :factors, limit: 3
    t.halfvec :half_embedding, limit: 3
    t.halfvec :half_factors, limit: 3
    t.bit :binary_embedding, limit: 3
    t.sparsevec :sparse_embedding, limit: 3
    t.sparsevec :sparse_factors, limit: 5
  end
  add_index :items, :cube_embedding, using: :gist
  add_index :items, :embedding, using: :hnsw, opclass: :vector_cosine_ops
  add_index :items, :half_embedding, using: :hnsw, opclass: :halfvec_cosine_ops
  add_index :items, :binary_embedding, using: :hnsw, opclass: :bit_hamming_ops
  add_index :items, :sparse_embedding, using: :hnsw, opclass: :sparsevec_cosine_ops
  add_index :items, "(embedding::halfvec(3)) halfvec_l2_ops", using: :hnsw
  add_index :items, "(binary_quantize(embedding)::bit(3)) bit_hamming_ops", using: :hnsw

  create_table :products, primary_key: [:store_id, :name], force: true do |t|
    t.integer :store_id
    t.string :name
    t.vector :embedding, limit: 3
  end
end

class Item < PostgresRecord
  has_neighbors :embedding, :cube_embedding, :half_embedding, :binary_embedding, :sparse_embedding
end

class CosineItem < PostgresRecord
  has_neighbors :embedding
  has_neighbors :cube_embedding, normalize: true
  self.table_name = "items"
end

class DimensionsItem < PostgresRecord
  has_neighbors :embedding, dimensions: 3
  has_neighbors :cube_embedding, dimensions: 3
  self.table_name = "items"
end

class LargeDimensionsItem < PostgresRecord
  has_neighbors :embedding, dimensions: 16001
  has_neighbors :cube_embedding, dimensions: 101
  self.table_name = "items"
end

class DefaultScopeItem < PostgresRecord
  default_scope { order(:id) }
  has_neighbors :embedding
  self.table_name = "items"
end

class Product < PostgresRecord
  has_neighbors :embedding
end

# ensure has_neighbors does not cause model schema to load
raise "has_neighbors loading model schema early" if Item.send(:schema_loaded?)

class PostgresTest < Minitest::Test
  def setup
    Item.delete_all
  end

  def assert_index_scan(relation)
    Item.transaction do
      Item.connection.execute("SET LOCAL enable_seqscan = off")
      assert_match "Index Scan", relation.limit(5).explain.inspect
    end
  end
end
