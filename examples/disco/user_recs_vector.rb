require "bundler/setup"
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

  create_table :users, force: true do |t|
    t.vector :factors, limit: 20
  end
end

class Movie < ActiveRecord::Base
  has_neighbors :factors
end

class User < ActiveRecord::Base
  has_neighbors :factors
end

data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)

movies = []
recommender.item_ids.each do |item_id|
  movies << {name: item_id, factors: recommender.item_factors(item_id)}
end
Movie.insert_all!(movies)

users = []
recommender.user_ids.each do |user_id|
  users << {id: user_id, factors: recommender.user_factors(user_id)}
end
User.insert_all!(users)

user = User.find(123)
pp Movie.nearest_neighbors(:factors, user.factors, distance: "inner_product").first(5).map(&:name)

# excludes rated, so will be different for some users
# pp recommender.user_recs(user.id).map { |v| v[:item_id] }
