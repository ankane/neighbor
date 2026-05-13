require_relative "test_helper"
require_relative "support/sqlite"

class SqliteFloat32Test < Minitest::Test
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

  def test_taxicab
    create_items(SqliteItem, :embedding)
    result = SqliteItem.find(1).nearest_neighbors(:embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_inner_product
    create_items(SqliteItem, :embedding)
    result = SqliteItem.find(1).nearest_neighbors(:embedding, distance: "inner_product").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [6, 4], result.map(&:neighbor_distance)
  end

  def test_create
    item = SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal [1, 2, 3], item.embedding
  end

  def test_invalid_dimensions
    error = assert_raises(ActiveRecord::RecordInvalid) do
      SqliteItem.create!(embedding: [1, 1])
    end
    assert_match "Validation failed: Embedding must have 3 dimensions", error.message
  end

  def test_infinite
    error = assert_raises(ActiveRecord::RecordInvalid) do
      SqliteItem.create!(embedding: [Float::INFINITY, 0, 0])
    end
    assert_equal "Validation failed: Embedding must have finite values", error.message
  end

  def test_nan
    error = assert_raises(ActiveRecord::RecordInvalid) do
      SqliteItem.create!(embedding: [Float::NAN, 0, 0])
    end
    assert_equal "Validation failed: Embedding must have finite values", error.message
  end
end
