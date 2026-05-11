require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
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

  def with_ignore_tables(value)
    previous_value = ActiveRecord::SchemaDumper.ignore_tables
    begin
      ActiveRecord::SchemaDumper.ignore_tables = value
      yield
    ensure
      ActiveRecord::SchemaDumper.ignore_tables = previous_value
    end
  end
end
