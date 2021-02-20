# Neighbor

Nearest neighbor search for Rails and Postgres

[![Build Status](https://github.com/ankane/neighbor/workflows/build/badge.svg?branch=master)](https://github.com/ankane/neighbor/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'neighbor'
```

And run:

```sh
bundle install
rails generate neighbor:install
rails db:migrate
```

This enables the [cube extension](https://www.postgresql.org/docs/current/cube.html) in Postgres

## Getting Started

Create a migration

```ruby
class AddNeighborVectorToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :neighbor_vector, :cube
  end
end
```

Add to your model

```ruby
class Item < ApplicationRecord
  has_neighbors dimensions: 3
end
```

Update the vectors

```ruby
item.update(neighbor_vector: [1.0, 1.2, 0.5])
```

> With cosine distance (the default), vectors are normalized before being stored

Get the nearest neighbors to a record

```ruby
item.nearest_neighbors.first(5)
```

Get the nearest neighbors to a vector [master]

```ruby
Item.nearest_neighbors([1, 2, 3])
```

## Distance

Specify the distance metric

```ruby
class Item < ApplicationRecord
  has_neighbors dimensions: 20, distance: "euclidean"
end
```

Supported values are:

- `cosine` (default)
- `euclidean`
- `taxicab`
- `chebyshev`

For inner product, see [this example](examples/disco_user_recs.rb)

Records returned from `nearest_neighbors` will have a `neighbor_distance` attribute

```ruby
nearest_item = item.nearest_neighbors.first
nearest_item.neighbor_distance
```

## Dimensions

By default, Postgres limits the `cube` data type to 100 dimensions. See the [Postgres docs](https://www.postgresql.org/docs/current/cube.html) for how to increase this.

## Example

You can use Neighbor for online item-based recommendations with [Disco](https://github.com/ankane/disco). We’ll use MovieLens data for this example.

Generate a model

```sh
rails generate model Movie name:string neighbor_vector:cube
rails db:migrate
```

And add `has_neighbors`

```ruby
class Movie < ApplicationRecord
  has_neighbors dimensions: 20
end
```

Fit the recommender

```ruby
data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)
```

Use item factors for the neighbor vector

```ruby
recommender.item_ids.each do |item_id|
  Movie.create!(name: item_id, neighbor_vector: recommender.item_factors(item_id))
end
```

And get similar movies

```ruby
movie = Movie.find_by(name: "Star Wars (1977)")
movie.nearest_neighbors.first(5).map(&:name)
```

[Complete code](examples/disco_item_recs.rb)

## History

View the [changelog](https://github.com/ankane/neighbor/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/ankane/neighbor/issues)
- Fix bugs and [submit pull requests](https://github.com/ankane/neighbor/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/ankane/neighbor.git
cd neighbor
bundle install
bundle exec rake test
```
