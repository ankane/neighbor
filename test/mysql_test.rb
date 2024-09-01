require_relative "test_helper"

class MysqlTest < Minitest::Test
  def setup
    MysqlItem.delete_all
  end

  def test_schema
    # TODO remove in 0.5.0
    skip

    file = Tempfile.new
    connection = ActiveRecord::VERSION::STRING.to_f >= 7.2 ? MysqlRecord.connection_pool : MysqlRecord.connection
    ActiveRecord::SchemaDumper.dump(connection, file)
    file.rewind
    contents = file.read
    refute_match "Could not dump table", contents
    assert_match %{t.vector "embedding", limit: 3}, contents
  end

  def test_works
    create_items(MysqlItem, :embedding)
    assert_equal [[1, 1, 1], [2, 2, 2], [1, 1, 2]], MysqlItem.order(:id).pluck(:embedding)
  end

  def test_vector_to_string
    MysqlItem.create!(embedding: [1, 2, 3])
    assert_equal "[1.00000e+00,2.00000e+00,3.00000e+00]", MysqlItem.pluck("VECTOR_TO_STRING(embedding)").last
  end

  def test_string_to_vector
    MysqlItem.connection.execute("INSERT INTO mysql_items (embedding) VALUES (STRING_TO_VECTOR('[1,2,3]'))")
    assert_equal [1, 2, 3], MysqlItem.last.embedding
  end
end