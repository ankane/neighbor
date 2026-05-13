require_relative "test_helper"
require_relative "support/sqlitevec"

class SqlitevecInt8Test < Minitest::Test
  def setup
    SqlitevecItem.delete_all
  end

  def test_cosine
    create_items(SqlitevecItem, :int8_embedding)
    result = SqlitevecItem.find(1).nearest_neighbors(:int8_embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(SqlitevecItem, :int8_embedding)
    result = SqlitevecItem.find(1).nearest_neighbors(:int8_embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(SqlitevecItem, :int8_embedding)
    result = SqlitevecItem.find(1).nearest_neighbors(:int8_embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end
end
