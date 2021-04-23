require "active_record"
require "disco"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :movies, force: true do |t|
    t.string :name
    t.vector :neighbor_vector, limit: 20
  end

  create_table :users, force: true do |t|
    t.vector :neighbor_vector, limit: 20
  end
end

class Movie < ActiveRecord::Base
  has_neighbors
end

class User < ActiveRecord::Base
  has_neighbors
end

data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)

movies = []
recommender.item_ids.each do |item_id|
  movies << {name: item_id, neighbor_vector: recommender.item_factors(item_id)}
end
Movie.insert_all!(movies) # use create! for Active Record < 6

users = []
recommender.user_ids.each do |user_id|
  users << {id: user_id, neighbor_vector: recommender.user_factors(user_id)}
end
User.insert_all!(users) # use create! for Active Record < 6

user = User.find(123)
pp Movie.nearest_neighbors(user.neighbor_vector, distance: "inner_product").first(5).map(&:name)

# excludes rated, so will be different for some users
# pp recommender.user_recs(user.id).map { |v| v[:item_id] }
