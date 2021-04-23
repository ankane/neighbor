require "active_record"
require "disco"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "cube"

  create_table :movies, force: true do |t|
    t.string :name
    t.cube :neighbor_vector
  end

  create_table :users, force: true do |t|
    t.cube :neighbor_vector
  end
end

# use an extra dimension to map inner product to euclidean
class Movie < ActiveRecord::Base
  has_neighbors dimensions: 21
end

class User < ActiveRecord::Base
  has_neighbors dimensions: 20
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
  movies << {name: item_id, neighbor_vector: recommender.item_factors(item_id).append(extra[i])}
end
Movie.insert_all(movies) # use create! for Active Record < 6

users = []
recommender.user_ids.each do |user_id|
  users << {id: user_id, neighbor_vector: recommender.user_factors(user_id)}
end
User.insert_all!(users) # use create! for Active Record < 6

user = User.find(123)
pp Movie.nearest_neighbors(user.neighbor_vector.append(0), distance: "euclidean").first(5).map(&:name)

# excludes rated, so will be different for some users
# pp recommender.user_recs(user.id).map { |v| v[:item_id] }
