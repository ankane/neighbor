module Neighbor
  class Railtie < Rails::Railtie
    generators do
      require "rails/generators/generated_attribute"

      # rails generate model Item embedding:vector{3}
      Rails::Generators::GeneratedAttribute.singleton_class.prepend(Neighbor::GeneratedAttribute)
    end
  end

  module GeneratedAttribute
    def parse_type_and_options(type, *, **)
      if type =~ /\A(vector|halfvec|bit|sparsevec)\{(\d+)\}\z/
        return $1, limit: $2.to_i
      end
      super
    end
  end
end
