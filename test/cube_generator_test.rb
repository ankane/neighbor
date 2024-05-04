require_relative "test_helper"

require "generators/neighbor/cube_generator"

class CubeGeneratorTest < Rails::Generators::TestCase
  tests Neighbor::Generators::CubeGenerator
  destination File.expand_path("../tmp", __dir__)
  setup :prepare_destination

  def test_works
    run_generator
    assert_migration "db/migrate/install_neighbor_cube.rb", /enable_extension "cube"/
  end
end
