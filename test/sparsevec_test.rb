require_relative "test_helper"

class SparsevecTest < Minitest::Test
  def setup
    skip unless vector?
    Item.delete_all
  end

  def test_cosine
    create_items(CosineItem, :sparse_embedding)
    result = CosineItem.find(1).nearest_neighbors(:sparse_embedding, distance: "cosine").first(3)
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

    Item.create!(sparse_factors: Neighbor::SparseVector.new(5, [1, 2, 4], [6, 7, 8]))
    factors = Item.last.sparse_factors
    assert_equal [0, 6, 7, 0, 8], factors.to_a
  end

  def test_from_dense
    embedding = Neighbor::SparseVector.from_dense([1, 0, 2, 0, 3])
    assert_equal 5, embedding.dimensions
    assert_equal [0, 2, 4], embedding.indices
    assert_equal [1, 2, 3], embedding.values
  end
end
