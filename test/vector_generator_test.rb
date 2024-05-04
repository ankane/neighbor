require_relative "test_helper"

require "generators/neighbor/vector_generator"

class VectorGeneratorTest < Rails::Generators::TestCase
  tests Neighbor::Generators::VectorGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def test_works
    run_generator
    assert_migration "db/migrate/install_neighbor_vector.rb", /enable_extension "vector"/
  end
end
