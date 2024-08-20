# Neighbor

Nearest neighbor search for Rails and Postgres

[![Build Status](https://github.com/ankane/neighbor/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/neighbor/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "neighbor"
```

## Choose An Extension

Neighbor supports two extensions: [cube](https://www.postgresql.org/docs/current/cube.html) and [vector](https://github.com/pgvector/pgvector). cube ships with Postgres, while vector supports more dimensions and approximate nearest neighbor search.

For cube, run:

```sh
rails generate neighbor:cube
rails db:migrate
```

For vector, [install pgvector](https://github.com/pgvector/pgvector#installation) and run:

```sh
rails generate neighbor:vector
rails db:migrate
```

## Getting Started

Create a migration

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :embedding, :cube
    # or
    add_column :items, :embedding, :vector, limit: 3 # dimensions
  end
end
```

Add to your model

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding
end
```

Update the vectors

```ruby
item.update(embedding: [1.0, 1.2, 0.5])
```

Get the nearest neighbors to a record

```ruby
item.nearest_neighbors(:embedding, distance: "euclidean").first(5)
```

Get the nearest neighbors to a vector

```ruby
Item.nearest_neighbors(:embedding, [0.9, 1.3, 1.1], distance: "euclidean").first(5)
```

## Distance

Supported values are:

- `euclidean`
- `cosine`
- `taxicab`
- `chebyshev` (cube only)
- `inner_product` (vector only)
- `hamming` (vector only)
- `jaccard` (vector only)

For cosine distance with cube, vectors must be normalized before being stored.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, normalize: true
end
```

For inner product with cube, see [this example](examples/disco_user_recs_cube.rb).

Records returned from `nearest_neighbors` will have a `neighbor_distance` attribute

```ruby
nearest_item = item.nearest_neighbors(:embedding, distance: "euclidean").first
nearest_item.neighbor_distance
```

## Dimensions

The cube data type can have up to 100 dimensions by default. See the [Postgres docs](https://www.postgresql.org/docs/current/cube.html) for how to increase this. The vector data type can have up to 16,000 dimensions, and vectors with up to 2,000 dimensions can be indexed.

For cube, it’s a good idea to specify the number of dimensions to ensure all records have the same number.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, dimensions: 3
end
```

## Indexing

For vector, add an approximate index to speed up queries. Create a migration with:

```ruby
class AddIndexToItemsEmbedding < ActiveRecord::Migration[7.1]
  def change
    add_index :items, :embedding, using: :hnsw, opclass: :vector_l2_ops
    # or
    add_index :items, :embedding, using: :ivfflat, opclass: :vector_l2_ops
  end
end
```

Use `:vector_cosine_ops` for cosine distance and `:vector_ip_ops` for inner product.

Set the size of the dynamic candidate list with HNSW

```ruby
Item.connection.execute("SET hnsw.ef_search = 100")
```

Or the number of probes with IVFFlat

```ruby
Item.connection.execute("SET ivfflat.probes = 3")
```

## Half-Precision Vectors

Use the `halfvec` type to store half-precision vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :embedding, :halfvec, limit: 3 # dimensions
  end
end
```

## Half-Precision Indexing

Index vectors at half precision for smaller indexes

```ruby
class AddIndexToItemsEmbedding < ActiveRecord::Migration[7.1]
  def change
    add_index :items, "(embedding::halfvec(3)) vector_l2_ops", using: :hnsw
  end
end
```

Get the nearest neighbors [unreleased]

```ruby
Item.nearest_neighbors(:embedding, [0.9, 1.3, 1.1], distance: "euclidean", precision: "half").first(5)
```

## Binary Vectors

Use the `bit` type to store binary vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :embedding, :bit, limit: 3 # dimensions
  end
end
```

Get the nearest neighbors by Hamming distance

```ruby
Item.nearest_neighbors(:embedding, "101", distance: "hamming").first(5)
```

## Binary Quantization

Use expression indexing for binary quantization

```ruby
class AddIndexToItemsEmbedding < ActiveRecord::Migration[7.1]
  def change
    add_index :items, "(binary_quantize(embedding)::bit(3)) bit_hamming_ops", using: :hnsw
  end
end
```

## Sparse Vectors

Use the `sparsevec` type to store sparse vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :embedding, :sparsevec, limit: 3 # dimensions
  end
end
```

Get the nearest neighbors

```ruby
embedding = Neighbor::SparseVector.new({0 => 0.9, 1 => 1.3, 2 => 1.1}, 3)
Item.nearest_neighbors(:embedding, embedding, distance: "euclidean").first(5)
```

## Examples

- [OpenAI Embeddings](#openai-embeddings)
- [Cohere Embeddings](#cohere-embeddings)
- [Sentence Embeddings](#sentence-embeddings)
- [Sparse Embeddings](#sparse-embeddings)
- [Disco Recommendations](#disco-recommendations)

### OpenAI Embeddings

Generate a model

```sh
rails generate model Document content:text embedding:vector{1536}
rails db:migrate
```

And add `has_neighbors`

```ruby
class Document < ApplicationRecord
  has_neighbors :embedding
end
```

Create a method to call the [embeddings API](https://platform.openai.com/docs/guides/embeddings)

```ruby
def fetch_embeddings(input)
  url = "https://api.openai.com/v1/embeddings"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    input: input,
    model: "text-embedding-3-small"
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers).tap(&:value)
  JSON.parse(response.body)["data"].map { |v| v["embedding"] }
end
```

Pass your input

```ruby
input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings(input)
```

Store the embeddings

```ruby
documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: embedding}
end
Document.insert_all!(documents)
```

And get similar documents

```ruby
document = Document.first
document.nearest_neighbors(:embedding, distance: "cosine").first(5).map(&:content)
```

See the [complete code](examples/openai_embeddings.rb)

### Cohere Embeddings

Generate a model

```sh
rails generate model Document content:text embedding:bit{1024}
rails db:migrate
```

And add `has_neighbors`

```ruby
class Document < ApplicationRecord
  has_neighbors :embedding
end
```

Create a method to call the [embed API](https://docs.cohere.com/reference/embed)

```ruby
def fetch_embeddings(input, input_type)
  url = "https://api.cohere.com/v1/embed"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("CO_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    texts: input,
    model: "embed-english-v3.0",
    input_type: input_type,
    embedding_types: ["ubinary"]
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers).tap(&:value)
  JSON.parse(response.body)["embeddings"]["ubinary"].map { |e| e.map { |v| v.chr.unpack1("B*") }.join }
end
```

Pass your input

```ruby
input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings(input, "search_document")
```

Store the embeddings

```ruby
documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: embedding}
end
Document.insert_all!(documents)
```

Embed the search query

```ruby
query = "forest"
query_embedding = fetch_embeddings([query], "search_query")[0]
```

And search the documents

```ruby
Document.nearest_neighbors(:embedding, query_embedding, distance: "hamming").first(5).map(&:content)
```

See the [complete code](examples/cohere_embeddings.rb)

### Sentence Embeddings

You can generate embeddings locally with [Transformers.rb](https://github.com/ankane/transformers-ruby).

Generate a model

```sh
rails generate model Document content:text embedding:vector{384}
rails db:migrate
```

And add `has_neighbors`

```ruby
class Document < ApplicationRecord
  has_neighbors :embedding
end
```

Load a [model](https://huggingface.co/sentence-transformers/all-MiniLM-L6-v2)

```ruby
model = Transformers::SentenceTransformer.new("sentence-transformers/all-MiniLM-L6-v2")
```

Pass your input

```ruby
input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.encode(input)
```

Store the embeddings

```ruby
documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: embedding}
end
Document.insert_all!(documents)
```

And get similar documents

```ruby
document = Document.first
document.nearest_neighbors(:embedding, distance: "cosine").first(5).map(&:content)
```

See the [complete code](examples/sentence_embeddings.rb)

### Sparse Embeddings

You can generate sparse embeddings locally with [Transformers.rb](https://github.com/ankane/transformers-ruby).

Generate a model

```sh
rails generate model Document content:text embedding:sparsevec{30522}
rails db:migrate
```

And add `has_neighbors`

```ruby
class Document < ApplicationRecord
  has_neighbors :embedding
end
```

Load a [model](https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1) to generate embeddings

```ruby
class EmbeddingModel
  def initialize(model_id)
    @model = Transformers::AutoModelForMaskedLM.from_pretrained(model_id)
    @tokenizer = Transformers::AutoTokenizer.from_pretrained(model_id)
    @special_token_ids = @tokenizer.special_tokens_map.map { |_, token| @tokenizer.vocab[token] }
  end

  def embed(input)
    feature = @tokenizer.(input, padding: true, truncation: true, return_tensors: "pt", return_token_type_ids: false)
    output = @model.(**feature)[0]
    values = Torch.max(output * feature[:attention_mask].unsqueeze(-1), dim: 1)[0]
    values = Torch.log(1 + Torch.relu(values))
    values[0.., @special_token_ids] = 0
    values.to_a
  end
end

model = EmbeddingModel.new("opensearch-project/opensearch-neural-sparse-encoding-v1")
```

Pass your input

```ruby
input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.embed(input)
```

Store the embeddings

```ruby
documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: Neighbor::SparseVector.new(embedding)}
end
Document.insert_all!(documents)
```

Embed the search query

```ruby
query = "forest"
query_embedding = model.embed([query])[0]
```

And search the documents

```ruby
Document.nearest_neighbors(:embedding, Neighbor::SparseVector.new(query_embedding), distance: "inner_product").first(5).map(&:content)
```

See the [complete code](examples/sparse_embeddings.rb)

### Disco Recommendations

You can use Neighbor for online item-based recommendations with [Disco](https://github.com/ankane/disco). We’ll use MovieLens data for this example.

Generate a model

```sh
rails generate model Movie name:string factors:cube
rails db:migrate
```

And add `has_neighbors`

```ruby
class Movie < ApplicationRecord
  has_neighbors :factors, dimensions: 20, normalize: true
end
```

Fit the recommender

```ruby
data = Disco.load_movielens
recommender = Disco::Recommender.new(factors: 20)
recommender.fit(data)
```

Store the item factors

```ruby
movies = []
recommender.item_ids.each do |item_id|
  movies << {name: item_id, factors: recommender.item_factors(item_id)}
end
Movie.insert_all!(movies)
```

And get similar movies

```ruby
movie = Movie.find_by(name: "Star Wars (1977)")
movie.nearest_neighbors(:factors, distance: "cosine").first(5).map(&:name)
```

See the complete code for [cube](examples/disco_item_recs_cube.rb) and [vector](examples/disco_item_recs_vector.rb)

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
createdb neighbor_test
bundle exec rake test
```
