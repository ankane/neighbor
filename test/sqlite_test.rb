require_relative "test_helper"

class SqliteTest < Minitest::Test
  def setup
    SqliteItem.delete_all
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

  def test_vec_to_json
    SqliteItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.000000,2.000000,3.000000]", SqliteItem.pluck("vec_to_json(embedding)").last
  end
end
