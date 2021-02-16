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

And get the nearest neighbors

```ruby
item.nearest_neighbors.first(5)
```

## Distances

Specify the distance metric

```ruby
class Item < ApplicationRecord
  has_neighbors dimensions: 20, distance: "euclidean"
end
```

Supported distances are:

- `cosine` (default)
- `euclidean`
- `taxicab`
- `chebyshev`

Returned records will have a `neighbor_distance` attribute

```ruby
returned_item.neighbor_distance
```

## Example

You can use Neighbor for online item recommendations with [Disco](https://github.com/ankane/disco). We’ll use MovieLens data for this example.

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
