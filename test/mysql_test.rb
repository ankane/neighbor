require_relative "test_helper"
require_relative "support/mysql"

class MysqlTest < Minitest::Test
  def setup
    MysqlItem.delete_all
  end

  def test_cosine
    skip "Requires HeatWave"

    create_items(MysqlItem, :embedding)
    result = MysqlItem.find(1).nearest_neighbors(:embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    skip "Requires HeatWave"

    create_items(MysqlItem, :embedding)
    result = MysqlItem.find(1).nearest_neighbors(:embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_hamming
    skip # TODO

    MysqlItem.create!(id: 1, binary_embedding: ["000"].pack("B*"))
    MysqlItem.create!(id: 2, binary_embedding: ["101"].pack("B*"))
    MysqlItem.create!(id: 3, binary_embedding: ["111"].pack("B*"))

    result = MysqlItem.find(1).nearest_neighbors(:binary_embedding, distance: "hamming").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [2, 3], result.map(&:neighbor_distance)
  end

  def test_create
    item = MysqlItem.create!(embedding: [1, 2, 3])
    assert_equal [1, 2, 3], item.embedding
  end

  def test_vector_to_string
    MysqlItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.00000e+00,2.00000e+00,3.00000e+00]", MysqlItem.pluck("VECTOR_TO_STRING(embedding)").last
  end

  def test_string_to_vector
    MysqlItem.connection.execute("INSERT INTO mysql_items (embedding) VALUES (STRING_TO_VECTOR('[1,2,3]'))")
    assert_equal [1, 2, 3], MysqlItem.last.embedding
  end

  def test_schema
    file = Tempfile.new
    connection = ActiveRecord::VERSION::STRING.to_f >= 7.2 ? MysqlRecord.connection_pool : MysqlRecord.connection
    ActiveRecord::SchemaDumper.dump(connection, file)
    file.rewind
    contents = file.read
    # TODO update in 0.5.0
    assert_match %{Could not dump table "mysql_items"}, contents
    # refute_match "Could not dump table", contents
    # assert_match %{t.vector "embedding", limit: 3}, contents
  end

  def test_invalid_dimensions
    skip # TODO remove in 0.5.0

    error = assert_raises(ActiveRecord::RecordInvalid) do
      MysqlItem.create!(embedding: [1, 1])
    end
    assert_equal "Validation failed: Embedding must have 3 dimensions", error.message
  end

  def test_infinite
    error = assert_raises(ActiveRecord::RecordInvalid) do
      MysqlItem.create!(embedding: [Float::INFINITY, 0, 0])
    end
    assert_equal "Validation failed: Embedding must have finite values", error.message
  end

  def test_nan
    error = assert_raises(ActiveRecord::RecordInvalid) do
      MysqlItem.create!(embedding: [Float::NAN, 0, 0])
    end
    assert_equal "Validation failed: Embedding must have finite values", error.message
  end
end
