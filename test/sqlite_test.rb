require_relative "test_helper"

class MariadbTest < Minitest::Test
  def setup
    SqliteItem.delete_all
  end

  def test_cosine
    create_items(SqliteItem, :embedding)
    result = SqliteItem.find(1).nearest_neighbors(:embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(SqliteItem, :embedding)
    result = SqliteItem.find(1).nearest_neighbors(:embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_vec_to_json
    SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.000000,2.000000,3.000000]", SqliteItem.pluck("vec_to_json(embedding)").last
  end
end
