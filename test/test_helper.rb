require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Schema.verbose = false unless ENV["VERBOSE"]
ActiveRecord::Base.logger = logger
ActiveRecord::Base.partial_inserts = false

class Minitest::Test
  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act
    end
  end

  def create_items(cls, attribute)
    vectors = [
      [1, 1, 1],
      [2, 2, 2],
      [1, 1, 2]
    ]
    vectors.each.with_index do |v, i|
      cls.create!(id: i + 1, attribute => v)
    end
  end

  def assert_index_scan(relation)
    Item.transaction do
      Item.connection.execute("SET LOCAL enable_seqscan = off")
      assert_match "Index Scan", relation.limit(5).explain.inspect
    end
  end

  def supports_normalizes?
    ActiveRecord::VERSION::STRING.to_f >= 7.1
  end
end
