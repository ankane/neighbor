require_relative "test_helper"
require_relative "support/vec1"

class Vec1VirtualTest < Minitest::Test
  def setup
    Vec1VirtualItem.delete_all
  end

  def test_euclidean
    create_items(Vec1VirtualItem, :embedding)

    embedding = Vec1VirtualItem.type_for_attribute(:embedding).serialize([1, 1, 1])
    items = Vec1VirtualItem.find_by_sql(["SELECT * FROM virtual_items(?, ?)", embedding, {k: 5}.to_json])
    assert_equal [1, 3, 2], items.pluck(:id)
  end
end
