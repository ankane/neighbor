require_relative "test_helper"

class MariadbTest < Minitest::Test
  def setup
    MariadbItem.delete_all
  end

  def test_works
    create_items(MariadbItem, :embedding)
    assert_equal [[1, 1, 1], [2, 2, 2], [1, 1, 2]], MariadbItem.order(:id).pluck(:embedding)
    assert_equal ["[1.000000,1.000000,1.000000]", "[2.000000,2.000000,2.000000]", "[1.000000,1.000000,2.000000]"], MariadbItem.order(:id).pluck("VEC_ToText(embedding)")
  end

  def test_euclidean
    create_items(MariadbItem, :embedding)
    result = MariadbItem.find(1).nearest_neighbors(:embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end
end
