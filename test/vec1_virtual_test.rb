require_relative "test_helper"
require_relative "support/vec1"

class Vec1VirtualTest < Minitest::Test
  def setup
    Vec1VirtualItem.delete_all
  end

  def test_euclidean
    create_items(Vec1VirtualItem, :embedding)

    items = Vec1VirtualItem.find_by_sql("SELECT * FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {k: 5}.to_json])
    assert_equal [1, 3, 2], items.pluck(:id)
  end

  def test_no_limit
    create_items(Vec1VirtualItem, :embedding)

    error = assert_raises(ActiveRecord::StatementInvalid) do
      Vec1VirtualItem.find_by_sql("SELECT * FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {}.to_json])
    end
    assert_match "no K value or visible LIMIT clause", error.message
  end
end
