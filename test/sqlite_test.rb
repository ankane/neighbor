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

  def test_index_scan
    # TODO
    # assert_index_scan SqliteItem.nearest_neighbors(:embedding, [0, 0, 0], distance: "euclidean")
    assert_index_scan SqliteItem.where("embedding MATCH ?", "[0, 0, 0]").order(:distance)
  end

  def test_index_scan_distance
    create_items(SqliteItem, :embedding)
    result = SqliteItem.where("embedding MATCH ?", "[1, 1, 1]").order(:distance).limit(3)
    assert_elements_in_delta [0, 1, Math.sqrt(3)], result.pluck(:distance)
  end

  def test_no_limit
    error = assert_raises(ActiveRecord::StatementInvalid) do
      # TODO
      # SqliteItem.nearest_neighbors(:embedding, [0, 0, 0], distance: "euclidean").load
      SqliteItem.where("embedding MATCH ?", "[0, 0, 0]").order(:distance).load
    end
    assert_match "A LIMIT or 'k = ?' constraint is required on vec0 knn queries.", error.message
  end

  def test_create
    item = SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal [1, 2, 3], item.embedding
  end

  def test_vec_to_json
    SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.000000,2.000000,3.000000]", SqliteItem.pluck("vec_to_json(embedding)").last
  end

  def test_schema
    file = Tempfile.new
    connection = ActiveRecord::VERSION::STRING.to_f >= 7.2 ? SqliteItem.connection_pool : SqliteItem.connection
    ActiveRecord::SchemaDumper.dump(connection, file)
    file.rewind
    contents = file.read
    if ActiveRecord::VERSION::MAJOR >= 8
      assert_match %{create_virtual_table "items", "vec0"}, contents
    else
      assert_match %{Could not dump table "items"}, contents
    end
  end

  def test_invalid_dimensions
    # TODO use validation / ActiveRecord::RecordInvalid instead
    error = assert_raises(ActiveRecord::StatementInvalid) do
      SqliteItem.create!(embedding: [1, 1])
    end
    assert_match "Expected 3 dimensions but received 2.", error.message
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

  def assert_index_scan(relation)
    assert_match "SCAN items VIRTUAL TABLE INDEX", relation.limit(5).explain.inspect
  end
end