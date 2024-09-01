require_relative "test_helper"

class MariadbTest < Minitest::Test
  def setup
    MariadbItem.delete_all
  end

  def test_euclidean
    create_items(MariadbItem, :embedding)
    result = MariadbItem.find(1).nearest_neighbors(:embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_vec_totext
    MariadbItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.000000,2.000000,3.000000]", MariadbItem.pluck("VEC_ToText(embedding)").last
  end

  def test_vec_fromtext
    MariadbItem.connection.execute("INSERT INTO mariadb_items (embedding) VALUES (Vec_FromText('[1,2,3]'))")
    assert_equal [1, 2, 3], MariadbItem.last.embedding
  end
end
