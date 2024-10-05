require "rails/generators"

module Neighbor
  module Generators
    class SqliteGenerator < Rails::Generators::Base
      source_root File.join(__dir__, "templates")

      def copy_templates
        template "sqlite.rb", "config/initializers/neighbor.rb"
      end
    end
  end
end
