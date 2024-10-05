require_relative "lib/neighbor/version"

Gem::Specification.new do |spec|
  spec.name          = "neighbor"
  spec.version       = Neighbor::VERSION
  spec.summary       = "Nearest neighbor search for Rails"
  spec.homepage      = "https://github.com/ankane/neighbor"
  spec.license       = "MIT"

  spec.author        = "Andrew Kane"
  spec.email         = "andrew@ankane.org"

  spec.files         = Dir["*.{md,txt}", "{lib}/**/*"]
  spec.require_path  = "lib"

  spec.required_ruby_version = ">= 3.1"

  spec.add_dependency "activerecord", ">= 7"
end
