require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Schema.verbose = false unless ENV["VERBOSE"]
ActiveRecord::Base.logger = logger

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"

ActiveRecord::Schema.define do
  enable_extension "cube"
  enable_extension "vector"

  create_table :items, force: true do |t|
    t.vector :embedding, limit: 3
    t.cube :cube_embedding
    t.halfvec :half_embedding, limit: 3
    t.bit :binary_embedding, limit: 3
    t.sparsevec :sparse_embedding, limit: 3
    t.vector :factors, limit: 3
    t.cube :cube_factors
    t.halfvec :half_factors, limit: 3
    t.sparsevec :sparse_factors, limit: 5
  end
end

class Item < ActiveRecord::Base
  has_neighbors :embedding, :cube_embedding, :half_embedding, :binary_embedding, :sparse_embedding
end

class CosineItem < ActiveRecord::Base
  has_neighbors :embedding
  has_neighbors :cube_embedding, normalize: true
  self.table_name = "items"
end

class DimensionsItem < ActiveRecord::Base
  has_neighbors :embedding, dimensions: 3
  has_neighbors :cube_embedding, dimensions: 3
  self.table_name = "items"
end

class LargeDimensionsItem < ActiveRecord::Base
  has_neighbors :embedding, dimensions: 16001
  has_neighbors :cube_embedding, dimensions: 101
  self.table_name = "items"
end

class Minitest::Test
  def setup
    Item.delete_all
  end

  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act
    end
  end

  def create_items(cls, attribute)
    vectors = [
      [1, 1, 1],
      [2, 2, 2],
      [1, 1, 2]
    ]
    vectors.each.with_index do |v, i|
      cls.create!(id: i + 1, attribute => v)
    end
  end
end
