require_relative "test_helper"

class BitTest < Minitest::Test
  def setup
    skip unless vector?
    Item.delete_all
  end

  def test_hamming
    Item.create!(id: 1, binary_embedding: "000")
    Item.create!(id: 2, binary_embedding: "101")
    Item.create!(id: 3, binary_embedding: "111")
    result = Item.nearest_neighbors(:binary_embedding, "101", distance: "hamming").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0, 1, 2], result.map(&:neighbor_distance)
  end

  def test_jaccard
    Item.create!(id: 1, binary_embedding: "000")
    Item.create!(id: 2, binary_embedding: "101")
    Item.create!(id: 3, binary_embedding: "111")
    result = Item.nearest_neighbors(:binary_embedding, "100", distance: "jaccard").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0.5, 2/3.0, 1], result.map(&:neighbor_distance)
  end
end
