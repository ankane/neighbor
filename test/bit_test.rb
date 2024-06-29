require_relative "test_helper"

class BitTest < Minitest::Test
  def test_hamming
    create_bit_items
    result = Item.find(1).nearest_neighbors(:binary_embedding, distance: "hamming").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [2, 3], result.map(&:neighbor_distance)
  end

  def test_hamming_scope
    create_bit_items
    result = Item.nearest_neighbors(:binary_embedding, "101", distance: "hamming").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0, 1, 2], result.map(&:neighbor_distance)
  end

  def test_hamming2
    create_bit_items
    result = Item.find(1).nearest_neighbors(:binary_embedding, distance: "hamming2").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [2, 3], result.map(&:neighbor_distance)
  end

  def test_hamming2_scope
    create_bit_items
    result = Item.nearest_neighbors(:binary_embedding, "101", distance: "hamming2").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0, 1, 2], result.map(&:neighbor_distance)
  end

  def test_jaccard
    create_bit_items
    result = Item.find(2).nearest_neighbors(:binary_embedding, distance: "jaccard").first(3)
    assert_equal [3, 1], result.map(&:id)
    assert_elements_in_delta [1/3.0, 1], result.map(&:neighbor_distance)
  end

  def test_jaccard_scope
    create_bit_items
    result = Item.nearest_neighbors(:binary_embedding, "100", distance: "jaccard").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0.5, 2/3.0, 1], result.map(&:neighbor_distance)
  end

  def test_index_scan
    assert_index_scan Item.nearest_neighbors(:binary_embedding, "101", distance: "hamming")
  end

  def test_invalid_dimensions
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(binary_embedding: "01")
    end
    assert_equal "Validation failed: Binary embedding must have 3 dimensions", error.message
  end

  def create_bit_items
    Item.create!(id: 1, binary_embedding: "000")
    Item.create!(id: 2, binary_embedding: "101")
    Item.create!(id: 3, binary_embedding: "111")
  end
end
