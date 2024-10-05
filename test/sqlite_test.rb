require_relative "test_helper"
require_relative "support/sqlite"

class SqliteTest < Minitest::Test
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

  def test_create
    item = SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal [1, 2, 3], item.embedding
  end

  def test_vec_to_json
    SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.000000,2.000000,3.000000]", SqliteItem.pluck("vec_to_json(embedding)").last
  end

  def test_virtual_table_cosine
    create_items(SqliteCosineItem, :embedding)

    relation = SqliteCosineItem.where("embedding MATCH ?", "[1, 1, 1]").order(:distance).limit(3)
    assert_elements_in_delta [0, 0, 0.05719095841050148], relation.pluck(:distance)
    assert_match "SCAN cosine_items VIRTUAL TABLE INDEX", relation.explain.inspect

    relation = SqliteCosineItem.where("embedding MATCH ? AND k = ?", "[1, 1, 1]", 3).order(:distance)
    assert_elements_in_delta [0, 0, 0.05719095841050148], relation.pluck(:distance)
  end

  def test_virtual_table_euclidean
    create_items(SqliteVecItem, :embedding)

    relation = SqliteVecItem.where("embedding MATCH ?", "[1, 1, 1]").order(:distance).limit(3)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], relation.pluck(:distance)
    assert_match "SCAN vec_items VIRTUAL TABLE INDEX", relation.explain.inspect

    relation = SqliteVecItem.where("embedding MATCH ? AND k = ?", "[1, 1, 1]", 3).order(:distance)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], relation.pluck(:distance)
  end

  def test_schema
    file = Tempfile.new
    connection = ActiveRecord::VERSION::STRING.to_f >= 7.2 ? SqliteItem.connection_pool : SqliteItem.connection
    ActiveRecord::SchemaDumper.dump(connection, file)
    file.rewind
    contents = file.read
    if ActiveRecord::VERSION::MAJOR >= 8
      assert_match %{t.binary "embedding"}, contents
      assert_match %{create_virtual_table "items", "vec0"}, contents
    else
      assert_match %{Could not dump table "vec_items"}, contents
    end
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
