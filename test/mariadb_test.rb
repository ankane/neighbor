require_relative "test_helper"
require_relative "support/mariadb"

class MariadbTest < Minitest::Test
  def setup
    MariadbItem.delete_all
  end

  def test_cosine
    create_items(MariadbCosineItem, :embedding)
    result = MariadbCosineItem.find(1).nearest_neighbors(:embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(MariadbItem, :embedding)
    result = MariadbItem.find(1).nearest_neighbors(:embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_index_scan
    skip "Occasionally freezes server"

    assert_index_scan MariadbItem.nearest_neighbors(:embedding, [0, 0, 0], distance: "euclidean")
  end

  def test_create
    item = MariadbItem.create!(embedding: [1, 2, 3])
    assert_equal [1, 2, 3], item.embedding
  end

  def test_vec_totext
    MariadbItem.create!(embedding: [1, 2, 3])
    assert_equal "[1,2,3]", MariadbItem.pluck("VEC_ToText(embedding)").last
  end

  def test_vec_fromtext
    MariadbItem.connection.execute("INSERT INTO mariadb_items (embedding) VALUES (Vec_FromText('[1,2,3]'))")
    assert_equal [1, 2, 3], MariadbItem.last.embedding
  end

  def test_invalid_dimensions
    error = assert_raises(ActiveRecord::RecordInvalid) do
      MariadbDimensionsItem.create!(embedding: [1, 1])
    end
    assert_equal "Validation failed: Embedding must have 3 dimensions", error.message
  end

  def test_infinite
    error = assert_raises(ActiveRecord::RecordInvalid) do
      MariadbItem.create!(embedding: [Float::INFINITY, 0, 0])
    end
    assert_equal "Validation failed: Embedding must have finite values", error.message
  end

  def test_nan
    error = assert_raises(ActiveRecord::RecordInvalid) do
      MariadbItem.create!(embedding: [Float::NAN, 0, 0])
    end
    assert_equal "Validation failed: Embedding must have finite values", error.message
  end

  def assert_index_scan(relation)
    assert_match "index_mariadb_items_on_embedding", relation.limit(5).explain.inspect
  end

  def test_normalize
    item = MariadbCosineItem.new
    item.embedding = [0, 3, 4]
    assert_elements_in_delta [0, 0.6, 0.8], item.embedding
    item.save!
    assert_elements_in_delta [0, 0.6, 0.8], item.embedding
    assert_elements_in_delta [0, 0.6, 0.8], MariadbItem.last.embedding
  end

  def test_insert
    MariadbCosineItem.insert!({embedding: [0, 3, 4]})
    expected = supports_normalizes? ? [0, 0.6, 0.8] : [0, 3, 4]
    assert_elements_in_delta expected, MariadbItem.last.embedding
  end

  def test_insert_all
    MariadbCosineItem.insert_all!([{embedding: [0, 3, 4]}])
    expected = supports_normalizes? ? [0, 0.6, 0.8] : [0, 3, 4]
    assert_elements_in_delta expected, MariadbItem.last.embedding
  end
end
