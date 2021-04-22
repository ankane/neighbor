require "bundler/setup"
Bundler.require(:default)
require "minitest/autorun"
require "minitest/pride"
require "active_record"

logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? STDOUT : nil)
ActiveRecord::Schema.verbose = false unless ENV["VERBOSE"]
ActiveRecord::Base.logger = logger

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"

def vector?
  ENV["EXT"] == "vector"
end

if vector?
  require_relative "support/vector"
else
  require_relative "support/cube"
end

class Minitest::Test
  def assert_elements_in_delta(expected, actual)
    assert_equal expected.size, actual.size
    expected.zip(actual) do |exp, act|
      assert_in_delta exp, act
    end
  end
end
