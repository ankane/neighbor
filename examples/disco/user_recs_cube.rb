require "bundler/setup"
require "active_record"
require "disco"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "cube"

  create_table :movies, force: true do |t|
    t.string :name
    t.cube :factors
  end

  create_table :users, force: true do |t|
    t.cube :factors
  end
end

# use an extra dimension to map inner product to euclidean
class Movie < ActiveRecord::Base
  has_neighbors :factors, dimensions: 21
end

class User < ActiveRecord::Base
  has_neighbors :factors, dimensions: 20
end

data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)

# inner product to euclidean
# https://gist.github.com/mdouze/e4bdb404dbd976c83fe447e529e5c9dc
norms = (recommender.item_factors ** 2).sum(axis: 1)
phi = norms.max
extra = Numo::SFloat::Math.sqrt(phi - norms)

movies = []
recommender.item_ids.each_with_index do |item_id, i|
  movies << {name: item_id, factors: recommender.item_factors(item_id).append(extra[i])}
end
Movie.insert_all!(movies)

users = []
recommender.user_ids.each do |user_id|
  users << {id: user_id, factors: recommender.user_factors(user_id)}
end
User.insert_all!(users)

user = User.find(123)
pp Movie.nearest_neighbors(:factors, user.factors.append(0), distance: "euclidean").first(5).map(&:name)

# excludes rated, so will be different for some users
# pp recommender.user_recs(user.id).map { |v| v[:item_id] }
