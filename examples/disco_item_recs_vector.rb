require "active_record"
require "disco"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :movies, force: true do |t|
    t.string :name
    t.vector :factors, limit: 20
  end
end

class Movie < ActiveRecord::Base
  has_neighbors :factors
end

data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)

movies = []
recommender.item_ids.each do |item_id|
  movies << {name: item_id, factors: recommender.item_factors(item_id)}
end
Movie.insert_all!(movies) # use create! for Active Record < 6

movie = Movie.find_by(name: "Star Wars (1977)")
pp movie.nearest_neighbors(:factors, distance: "cosine").first(5).map(&:name)
