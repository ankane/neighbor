require_relative "test_helper"
require_relative "support/mysql"

class MysqlBitTest < Minitest::Test
  def setup
    MysqlItem.delete_all
  end

  def test_hamming
    create_bit_items
    result = MysqlItem.find(1).nearest_neighbors(:binary_embedding, distance: "hamming").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [2, 3].map { |v| v * 1024 }, result.map(&:neighbor_distance)
  end

  def test_hamming_scope
    create_bit_items
    result = MysqlItem.nearest_neighbors(:binary_embedding, "\x05" * 1024, distance: "hamming").first(5)
    assert_equal [2, 3, 1], result.map(&:id)
    assert_elements_in_delta [0, 1, 2].map { |v| v * 1024 }, result.map(&:neighbor_distance)
  end

  def test_invalid_dimensions
    error = assert_raises(ActiveRecord::RecordInvalid) do
      MysqlItem.create!(binary_embedding: "\x00" * 1024 + "\x11")
    end
    assert_equal "Validation failed: Binary embedding must have 8192 dimensions", error.message
  end

  def create_bit_items
    MysqlItem.create!(id: 1, binary_embedding: "\x00" * 1024)
    MysqlItem.create!(id: 2, binary_embedding: "\x05" * 1024)
    MysqlItem.create!(id: 3, binary_embedding: "\x07" * 1024)
  end
end
