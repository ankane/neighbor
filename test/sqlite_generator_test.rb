require_relative "test_helper"

require "generators/neighbor/sqlite_generator"

class SqliteGeneratorTest < Rails::Generators::TestCase
  tests Neighbor::Generators::SqliteGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def test_works
    run_generator
    assert_file "config/initializers/neighbor.rb", /Neighbor::SQLite.initialize!/
  end
end
