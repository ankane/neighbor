require_relative "test_helper"
require_relative "support/postgresql"

class SparsevecTest < Minitest::Test
  def setup
    Item.delete_all
  end

  def test_cosine
    create_items(Item, :sparse_embedding)
    result = Item.find(1).nearest_neighbors(:sparse_embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(Item, :sparse_embedding)
    result = Item.find(1).nearest_neighbors(:sparse_embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(Item, :sparse_embedding)
    result = Item.find(1).nearest_neighbors(:sparse_embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_inner_product
    create_items(Item, :sparse_embedding)
    result = Item.find(1).nearest_neighbors(:sparse_embedding, distance: "inner_product").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [6, 4], result.map(&:neighbor_distance)
  end

  def test_index_scan
    assert_index_scan Item.nearest_neighbors(:sparse_embedding, [0, 0, 0], distance: "cosine")
  end

  def test_half_precision
    create_items(Item, :sparse_embedding)
    error = assert_raises(ArgumentError) do
      Item.nearest_neighbors(:sparse_embedding, [0, 0, 0], distance: "euclidean", precision: "half")
    end
    assert_equal "Precision not supported for this type", error.message
  end

  def test_type
    Item.create!(sparse_factors: "{1:1,3:2,5:3}/5")
    factors = Item.last.sparse_factors
    assert_equal 5, factors.dimensions
    assert_equal [0, 2, 4], factors.indices
    assert_equal [1, 2, 3], factors.values
    assert_equal [1, 0, 2, 0, 3], factors.to_a

    Item.create!(sparse_factors: [0, 4, 0, 5, 0])
    factors = Item.last.sparse_factors
    assert_equal [0, 4, 0, 5, 0], factors.to_a

    Item.create!(sparse_factors: Neighbor::SparseVector.new({1 => 6, 2 => 7, 4 => 8}, 5))
    factors = Item.last.sparse_factors
    assert_equal [0, 6, 7, 0, 8], factors.to_a
  end

  def test_from_dense
    embedding = Neighbor::SparseVector.new([1, 0, 2, 0, 3, 0])
    assert_equal [1, 0, 2, 0, 3, 0], embedding.to_a
    assert_equal 6, embedding.dimensions
    assert_equal [0, 2, 4], embedding.indices
    assert_equal [1, 2, 3], embedding.values
  end

  def test_invalid_dimensions
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(sparse_embedding: Neighbor::SparseVector.new({}, 2))
    end
    assert_equal "Validation failed: Sparse embedding must have 3 dimensions", error.message
  end

  def test_infinite
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(sparse_embedding: [Float::INFINITY, 0, 0])
    end
    assert_equal "Validation failed: Sparse embedding must have finite values", error.message
  end

  def test_nan
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(sparse_embedding: [Float::NAN, 0, 0])
    end
    assert_equal "Validation failed: Sparse embedding must have finite values", error.message
  end
end
