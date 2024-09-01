require_relative "test_helper"

class MysqlTest < Minitest::Test
  def setup
    skip unless ENV["TEST_MYSQL"]
  end

  def test_schema
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
    assert_equal ["[1.00000e+00,1.00000e+00,1.00000e+00]", "[2.00000e+00,2.00000e+00,2.00000e+00]", "[1.00000e+00,1.00000e+00,2.00000e+00]"], MysqlItem.order(:id).pluck("VECTOR_TO_STRING(embedding)")
  end
end
