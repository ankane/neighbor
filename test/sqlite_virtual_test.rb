require_relative "test_helper"
require_relative "support/sqlite"

class SqliteVirtualTest < Minitest::Test
  def setup
    SqliteVecItem.delete_all
    SqliteCosineItem.delete_all
  end

  def test_cosine
    create_items(SqliteCosineItem, :embedding)

    relation = SqliteCosineItem.where("embedding MATCH ?", "[1, 1, 1]").order(:distance).limit(3)
    assert_elements_in_delta [0, 0, 0.05719095841050148], relation.pluck(:distance)
    assert_match "SCAN cosine_items VIRTUAL TABLE INDEX", relation.explain.inspect

    relation = SqliteCosineItem.where("embedding MATCH ? AND k = ?", "[1, 1, 1]", 3).order(:distance)
    assert_elements_in_delta [0, 0, 0.05719095841050148], relation.pluck(:distance)
  end

  def test_euclidean
    create_items(SqliteVecItem, :embedding)

    relation = SqliteVecItem.where("embedding MATCH ?", [1, 1, 1].to_s).order(:distance).limit(3)
    assert_equal [1, 3, 2], relation.all.map(&:id)
    assert_equal [1, 3, 2], relation.pluck(:id)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], relation.pluck(:distance)
    assert_match "SCAN vec_items VIRTUAL TABLE INDEX", relation.explain.inspect

    relation = SqliteVecItem.where("embedding MATCH ? AND k = ?", [1, 1, 1].to_s, 3).order(:distance)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], relation.pluck(:distance)
  end

  def test_no_limit
    error = assert_raises(ActiveRecord::StatementInvalid) do
      SqliteVecItem.where("embedding MATCH ?", "[0, 0, 0]").order(:distance).load
    end
    assert_match "A LIMIT or 'k = ?' constraint is required on vec0 knn queries.", error.message
  end

  def test_where_limit
    skip if SQLite3::VERSION.to_i < 2

    error = assert_raises(ActiveRecord::StatementInvalid) do
      SqliteVecItem.where.not(embedding: nil).where("embedding MATCH ?", "[0, 0, 0]").order(:distance).limit(3).load
    end
    assert_match "A LIMIT or 'k = ?' constraint is required on vec0 knn queries.", error.message
  end

  def test_where_k
    assert SqliteVecItem.where.not(embedding: nil).where("embedding MATCH ? AND k = ?", "[0, 0, 0]", 3).order(:distance).load
  end

  def test_where_id
    create_items(SqliteVecItem, :embedding)

    relation = SqliteVecItem.where(id: [2, 3]).where("embedding MATCH ?", [1, 1, 1].to_s).where(k: 5).order(:distance)
    assert_equal [3, 2], relation.pluck(:id)
  end

  def test_create_returning_id
    item = SqliteVecItem.create!(embedding: [1, 2, 3])
    # TODO figure out why id not set
    assert_nil item.id
    assert_kind_of Integer, SqliteVecItem.last.id
  end
end
