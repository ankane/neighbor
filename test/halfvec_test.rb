require_relative "test_helper"

class HalfvecTest < Minitest::Test
  def setup
    skip unless vector?
    Item.delete_all
  end

  def test_cosine
    create_items(CosineItem, :half_embedding)
    result = CosineItem.find(1).nearest_neighbors(:half_embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_inner_product
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "inner_product").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [6, 4], result.map(&:neighbor_distance)
  end
end