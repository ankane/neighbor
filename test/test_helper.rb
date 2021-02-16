require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Schema.verbose = false unless ENV["VERBOSE"]
ActiveRecord::Base.logger = logger

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"

ActiveRecord::Schema.define do
  enable_extension "cube"

  create_table :items, force: true do |t|
    t.column :neighbor_vector, :cube
  end
end

class Item < ActiveRecord::Base
  has_neighbors dimensions: 3
end

class EuclideanItem < ActiveRecord::Base
  has_neighbors dimensions: 3, distance: "euclidean"
  self.table_name = "items"
end

class TaxicabItem < ActiveRecord::Base
  has_neighbors dimensions: 3, distance: "taxicab"
  self.table_name = "items"
end

class ChebyshevItem < ActiveRecord::Base
  has_neighbors dimensions: 3, distance: "chebyshev"
  self.table_name = "items"
end

class LargeDimensionsItem < ActiveRecord::Base
  has_neighbors dimensions: 101
  self.table_name = "items"
end

class Minitest::Test
  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act
    end
  end
end
