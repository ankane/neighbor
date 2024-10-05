require_relative "test_helper"
require_relative "support/sqlite"

class SqliteBitTest < Minitest::Test
  def setup
    SqliteItem.delete_all
  end

  def test_hamming
    create_bit_items
    result = SqliteItem.find(1).nearest_neighbors(:binary_embedding, distance: "hamming").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [2, 3], result.map(&:neighbor_distance)
  end

  def test_hamming_scope
    create_bit_items
    result = SqliteItem.nearest_neighbors(:binary_embedding, "\x05", distance: "hamming").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0, 1, 2], result.map(&:neighbor_distance)
  end

  def create_bit_items
    SqliteItem.create!(id: 1, binary_embedding: "\x00")
    SqliteItem.create!(id: 2, binary_embedding: "\x05")
    SqliteItem.create!(id: 3, binary_embedding: "\x07")
  end
end
