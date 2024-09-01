require_relative "test_helper"

class MariadbTest < Minitest::Test
  def test_works
    create_items(MariadbItem, :embedding)
    assert_equal [[1, 1, 1], [2, 2, 2], [1, 1, 2]], MariadbItem.order(:id).pluck(:embedding)
    assert_equal ["[1.000000,1.000000,1.000000]", "[2.000000,2.000000,2.000000]", "[1.000000,1.000000,2.000000]"], MariadbItem.order(:id).pluck("VEC_ToText(embedding)")
  end
end
