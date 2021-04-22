# Neighbor

Nearest neighbor search for Rails and Postgres

[![Build Status](https://github.com/ankane/neighbor/workflows/build/badge.svg?branch=master)](https://github.com/ankane/neighbor/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem 'neighbor'
```

## Choose An Extension

Neighbor supports two extensions: [cube](https://www.postgresql.org/docs/current/cube.html) and [vector](https://github.com/ankane/pgvector). cube ships with Postgres, while vector supports approximate nearest neighbor search.

For cube, run:

```sh
rails generate neighbor:cube
rails db:migrate
```

For vector, install [pgvector](https://github.com/ankane/pgvector#installation) and run:

```sh
rails generate neighbor:vector
rails db:migrate
```

## Getting Started

Create a migration

```ruby
class AddNeighborVectorToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :neighbor_vector, :cube
    # or
    add_column :items, :neighbor_vector, :vector, limit: 3
  end
end
```

Add to your model

```ruby
class Item < ApplicationRecord
  has_neighbors
end
```

Update the vectors

```ruby
item.update(neighbor_vector: [1.0, 1.2, 0.5])
```

Get the nearest neighbors to a record

```ruby
item.nearest_neighbors(distance: "euclidean").first(5)
```

Get the nearest neighbors to a vector

```ruby
Item.nearest_neighbors([0.9, 1.3, 1.1], distance: "euclidean").first(5)
```

## Distance

Supported values are:

- `euclidean`
- `cosine`
- `taxicab` (cube only)
- `chebyshev` (cube only)
- `inner_product` (vector only)

For cosine distance with cube, vectors must be normalized before being stored.

```ruby
class Item < ApplicationRecord
  has_neighbors normalize: true
end
```

For inner product with cube, see [this example](examples/disco_user_recs.rb).

Records returned from `nearest_neighbors` will have a `neighbor_distance` attribute

```ruby
nearest_item = item.nearest_neighbors(distance: "euclidean").first
nearest_item.neighbor_distance
```

## Dimensions

The cube data type is limited 100 dimensions by default. See the [Postgres docs](https://www.postgresql.org/docs/current/cube.html) for how to increase this. The vector data type is limited to 1024 dimensions.

For cube, it’s a good idea to specify the number of dimensions to ensure all records have the same number.

```ruby
class Movie < ApplicationRecord
  has_neighbors dimensions: 3
end
```

## Indexing

For vector, add an approximate index to speed up queries. Create a migration with:

```ruby
class AddIndexToItemsNeighborVector < ActiveRecord::Migration[6.1]
  def change
    add_index :items, :neighbor_vector, using: :ivfflat
  end
end
```

Add `opclass: :vector_cosine_ops` for cosine distance and `opclass: :vector_ip_ops` for inner product.

Set the number of probes

```ruby
Item.connection.execute("SET ivfflat.probes = 3")
```

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
  has_neighbors dimensions: 20, normalize: true
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
movie.nearest_neighbors(distance: "cosine").first(5).map(&:name)
```

[Complete code](examples/disco_item_recs.rb)

## Upgrading

### 0.2.0

The `distance` option has been moved from `has_neighbors` to `nearest_neighbors`, and there is no longer a default. If you use cosine distance, set:

```ruby
class Item < ApplicationRecord
  has_neighbors normalize: true
end
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
