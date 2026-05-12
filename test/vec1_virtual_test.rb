require_relative "test_helper"
require_relative "support/vec1"

class Vec1VirtualTest < Minitest::Test
  def setup
    Vec1VirtualItem.delete_all
  end

  def test_cosine
    Vec1VirtualItem.create!(cmd: "rebuild", arg: {index: "none", distance: "cos"}.to_json)
    create_items(Vec1VirtualItem, :embedding)

    items = Vec1VirtualItem.find_by_sql("SELECT * FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {k: 5}.to_json])
    assert_equal [1, 2, 3], items.pluck(:id)
  end

  def test_euclidean
    Vec1VirtualItem.create!(cmd: "rebuild", arg: {index: "none", distance: "l2"}.to_json)
    create_items(Vec1VirtualItem, :embedding)

    items = Vec1VirtualItem.find_by_sql("SELECT * FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {k: 5}.to_json])
    assert_equal [1, 3, 2], items.pluck(:id)
  end

  def test_flat_cosine
    Vec1VirtualItem.create!(cmd: "rebuild", arg: {index: "flat", distance: "cos"}.to_json)
    create_items(Vec1VirtualItem, :embedding)

    items = Vec1VirtualItem.find_by_sql("SELECT *, distance FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {k: 5}.to_json])
    assert_elements_in_delta [0, 0, 0.05719095841050148], items.pluck(:distance)
  end

  def test_flat_euclidean
    Vec1VirtualItem.create!(cmd: "rebuild", arg: {index: "flat", distance: "l2"}.to_json)
    create_items(Vec1VirtualItem, :embedding)

    items = Vec1VirtualItem.find_by_sql("SELECT *, sqrt(distance) AS distance FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {k: 5}.to_json])
    assert_equal [1, 3, 2], items.pluck(:id)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], items.pluck(:distance)
  end

  def test_train
    create_items(Vec1VirtualItem, :embedding)
    Vec1VirtualItem.connection.execute("INSERT INTO virtual_items (cmd, arg) VALUES ('rebuild', (SELECT vec1_train(embedding, '{codesize: 0}') FROM virtual_items))")

    items = Vec1VirtualItem.find_by_sql("SELECT *, sqrt(distance) AS distance FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {k: 5}.to_json])
    assert_equal [1, 3, 2], items.pluck(:id)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], items.pluck(:distance)
  end

  def test_no_limit
    create_items(Vec1VirtualItem, :embedding)

    error = assert_raises(ActiveRecord::StatementInvalid) do
      Vec1VirtualItem.find_by_sql("SELECT * FROM virtual_items(vec1_from_json(?), ?)", [[1, 1, 1].to_json, {}.to_json])
    end
    assert_match "no K value or visible LIMIT clause", error.message
  end
end
