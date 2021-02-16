require "active_record"
require "disco"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "cube"

  create_table :movies, force: true do |t|
    t.string :name
    t.column :neighbor_vector, :cube
  end
end

class Movie < ActiveRecord::Base
  has_neighbors dimensions: 20
end

data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)

recommender.item_ids.each do |item_id|
  Movie.create!(name: item_id, neighbor_vector: recommender.item_factors(item_id))
end

movie = Movie.find_by(name: "Star Wars (1977)")
pp movie.nearest_neighbors.first(5).map(&:name)
