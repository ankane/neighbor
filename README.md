# Neighbor

Nearest neighbor search for Rails

Supports:

- Postgres (cube and pgvector)
- SQLite (sqlite-vec) - experimental
- MariaDB 11.7 - experimental
- MySQL 9 (searching requires HeatWave) - experimental

[![Build Status](https://github.com/ankane/neighbor/actions/workflows/build.yml/badge.svg)](https://github.com/ankane/neighbor/actions)

## Installation

Add this line to your application’s Gemfile:

```ruby
gem "neighbor"
```

### For Postgres

Neighbor supports two extensions: [cube](https://www.postgresql.org/docs/current/cube.html) and [pgvector](https://github.com/pgvector/pgvector). cube ships with Postgres, while pgvector supports more dimensions and approximate nearest neighbor search.

For cube, run:

```sh
rails generate neighbor:cube
rails db:migrate
```

For pgvector, [install the extension](https://github.com/pgvector/pgvector#installation) and run:

```sh
rails generate neighbor:vector
rails db:migrate
```

### For SQLite

Add this line to your application’s Gemfile:

```ruby
gem "sqlite-vec"
```

And run:

```sh
rails generate neighbor:sqlite
```

## Getting Started

Create a migration

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
  def change
    # cube
    add_column :items, :embedding, :cube

    # pgvector, MariaDB, and MySQL
    add_column :items, :embedding, :vector, limit: 3 # dimensions

    # sqlite-vec
    add_column :items, :embedding, :binary
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

Records returned from `nearest_neighbors` will have a `neighbor_distance` attribute

```ruby
nearest_item = item.nearest_neighbors(:embedding, distance: "euclidean").first
nearest_item.neighbor_distance
```

See the additional docs for:

- [cube](#cube)
- [pgvector](#pgvector)
- [sqlite-vec](#sqlite-vec)
- [MariaDB](#mariadb)
- [MySQL](#mysql)

Or check out some [examples](#examples)

## cube

### Distance

Supported values are:

- `euclidean`
- `cosine`
- `taxicab`
- `chebyshev`

For cosine distance with cube, vectors must be normalized before being stored.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, normalize: true
end
```

For inner product with cube, see [this example](examples/disco/user_recs_cube.rb).

### Dimensions

The `cube` type can have up to 100 dimensions by default. See the [Postgres docs](https://www.postgresql.org/docs/current/cube.html) for how to increase this.

For cube, it’s a good idea to specify the number of dimensions to ensure all records have the same number.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, dimensions: 3
end
```

## pgvector

### Distance

Supported values are:

- `euclidean`
- `inner_product`
- `cosine`
- `taxicab`
- `hamming`
- `jaccard`

### Dimensions

The `vector` type can have up to 16,000 dimensions, and vectors with up to 2,000 dimensions can be indexed.

The `halfvec` type can have up to 16,000 dimensions, and half vectors with up to 4,000 dimensions can be indexed.

The `bit` type can have up to 83 million dimensions, and bit vectors with up to 64,000 dimensions can be indexed.

The `sparsevec` type can have up to 16,000 non-zero elements, and sparse vectors with up to 1,000 non-zero elements can be indexed.

### Indexing

Add an approximate index to speed up queries. Create a migration with:

```ruby
class AddIndexToItemsEmbedding < ActiveRecord::Migration[8.0]
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

### Half-Precision Vectors

Use the `halfvec` type to store half-precision vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :embedding, :halfvec, limit: 3 # dimensions
  end
end
```

### Half-Precision Indexing

Index vectors at half precision for smaller indexes

```ruby
class AddIndexToItemsEmbedding < ActiveRecord::Migration[8.0]
  def change
    add_index :items, "(embedding::halfvec(3)) vector_l2_ops", using: :hnsw
  end
end
```

Get the nearest neighbors

```ruby
Item.nearest_neighbors(:embedding, [0.9, 1.3, 1.1], distance: "euclidean", precision: "half").first(5)
```

### Binary Vectors

Use the `bit` type to store binary vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :embedding, :bit, limit: 3 # dimensions
  end
end
```

Get the nearest neighbors by Hamming distance

```ruby
Item.nearest_neighbors(:embedding, "101", distance: "hamming").first(5)
```

### Binary Quantization

Use expression indexing for binary quantization

```ruby
class AddIndexToItemsEmbedding < ActiveRecord::Migration[8.0]
  def change
    add_index :items, "(binary_quantize(embedding)::bit(3)) bit_hamming_ops", using: :hnsw
  end
end
```

### Sparse Vectors

Use the `sparsevec` type to store sparse vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
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

## sqlite-vec

### Distance

Supported values are:

- `euclidean`
- `cosine`
- `taxicab`
- `hamming`

### Dimensions

For sqlite-vec, it’s a good idea to specify the number of dimensions to ensure all records have the same number.

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, dimensions: 3
end
```

### Virtual Tables

You can also use [virtual tables](https://alexgarcia.xyz/sqlite-vec/features/knn.html)

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
  def change
    # Rails 8+
    create_virtual_table :items, :vec0, [
      "id integer PRIMARY KEY AUTOINCREMENT NOT NULL",
      "embedding float[3] distance_metric=L2"
    ]

    # Rails < 8
    execute <<~SQL
      CREATE VIRTUAL TABLE items USING vec0(
        id integer PRIMARY KEY AUTOINCREMENT NOT NULL,
        embedding float[3] distance_metric=L2
      )
    SQL
  end
end
```

Use `distance_metric=cosine` for cosine distance

You can optionally ignore any shadow tables that are created

```ruby
ActiveRecord::SchemaDumper.ignore_tables += [
  "items_chunks", "items_rowids", "items_vector_chunks00"
]
```

Get the `k` nearest neighbors

```ruby
Item.where("embedding MATCH ?", [1, 2, 3].to_s).where(k: 5).order(:distance)
```

Filter by primary key

```ruby
Item.where(id: [2, 3]).where("embedding MATCH ?", [1, 2, 3].to_s).where(k: 5).order(:distance)
```

### Int8 Vectors

Use the `type` option for int8 vectors

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, dimensions: 3, type: :int8
end
```

### Binary Vectors

Use the `type` option for binary vectors

```ruby
class Item < ApplicationRecord
  has_neighbors :embedding, dimensions: 8, type: :bit
end
```

Get the nearest neighbors by Hamming distance

```ruby
Item.nearest_neighbors(:embedding, "\x05", distance: "hamming").first(5)
```

## MariaDB

### Distance

Supported values are:

- `euclidean`
- `cosine`
- `hamming`

### Indexing

Vector columns must use `null: false` to add a vector index

```ruby
class CreateItems < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.vector :embedding, limit: 3, null: false
      t.index :embedding, type: :vector
    end
  end
end
```

### Binary Vectors

Use the `bigint` type to store binary vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :embedding, :bigint
  end
end
```

Note: Binary vectors can have up to 64 dimensions

Get the nearest neighbors by Hamming distance

```ruby
Item.nearest_neighbors(:embedding, 5, distance: "hamming").first(5)
```

## MySQL

### Distance

Supported values are:

- `euclidean`
- `cosine`
- `hamming`

Note: The `DISTANCE()` function is [only available on HeatWave](https://dev.mysql.com/doc/refman/9.0/en/vector-functions.html)

### Binary Vectors

Use the `binary` type to store binary vectors

```ruby
class AddEmbeddingToItems < ActiveRecord::Migration[8.0]
  def change
    add_column :items, :embedding, :binary
  end
end
```

Get the nearest neighbors by Hamming distance

```ruby
Item.nearest_neighbors(:embedding, "\x05", distance: "hamming").first(5)
```

## Examples

- [Embeddings](#openai-embeddings) with OpenAI
- [Binary embeddings](#cohere-embeddings) with Cohere
- [Sentence embeddings](#sentence-embeddings) with Informers
- [Hybrid search](#hybrid-search) with Informers
- [Sparse search](#sparse-search) with Transformers.rb
- [Recommendations](#disco-recommendations) with Disco

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

See the [complete code](examples/openai/example.rb)

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

See the [complete code](examples/cohere/example.rb)

### Sentence Embeddings

You can generate embeddings locally with [Informers](https://github.com/ankane/informers).

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
model = Informers.pipeline("embedding", "sentence-transformers/all-MiniLM-L6-v2")
```

Pass your input

```ruby
input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.(input)
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

See the [complete code](examples/informers/example.rb)

### Hybrid Search

You can use Neighbor for hybrid search with [Informers](https://github.com/ankane/informers).

Generate a model

```sh
rails generate model Document content:text embedding:vector{768}
rails db:migrate
```

And add `has_neighbors` and a scope for keyword search

```ruby
class Document < ApplicationRecord
  has_neighbors :embedding

  scope :search, ->(query) {
    where("to_tsvector(content) @@ plainto_tsquery(?)", query)
      .order(Arel.sql("ts_rank_cd(to_tsvector(content), plainto_tsquery(?)) DESC", query))
  }
end
```

Create some documents

```ruby
Document.create!(content: "The dog is barking")
Document.create!(content: "The cat is purring")
Document.create!(content: "The bear is growling")
```

Generate an embedding for each document

```ruby
embed = Informers.pipeline("embedding", "Snowflake/snowflake-arctic-embed-m-v1.5")
embed_options = {model_output: "sentence_embedding", pooling: "none"} # specific to embedding model

Document.find_each do |document|
  embedding = embed.(document.content, **embed_options)
  document.update!(embedding: embedding)
end
```

Perform keyword search

```ruby
query = "growling bear"
keyword_results = Document.search(query).limit(20).load_async
```

And semantic search in parallel (the query prefix is specific to the [embedding model](https://huggingface.co/Snowflake/snowflake-arctic-embed-m-v1.5))

```ruby
query_prefix = "Represent this sentence for searching relevant passages: "
query_embedding = embed.(query_prefix + query, **embed_options)
semantic_results =
  Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(20).load_async
```

To combine the results, use Reciprocal Rank Fusion (RRF)

```ruby
Neighbor::Reranking.rrf(keyword_results, semantic_results).first(5)
```

Or a reranking model

```ruby
rerank = Informers.pipeline("reranking", "mixedbread-ai/mxbai-rerank-xsmall-v1")
results = (keyword_results + semantic_results).uniq
rerank.(query, results.map(&:content)).first(5).map { |v| results[v[:doc_id]] }
```

See the [complete code](examples/hybrid/example.rb)

### Sparse Search

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

See the [complete code](examples/sparse/example.rb)

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
Movie.create!(movies)
```

And get similar movies

```ruby
movie = Movie.find_by(name: "Star Wars (1977)")
movie.nearest_neighbors(:factors, distance: "cosine").first(5).map(&:name)
```

See the complete code for [cube](examples/disco/item_recs_cube.rb) and [pgvector](examples/disco/item_recs_vector.rb)

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

# Postgres
createdb neighbor_test
bundle exec rake test:postgresql

# SQLite
bundle exec rake test:sqlite

# MariaDB
docker run -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 -e MARIADB_DATABASE=neighbor_test -p 3307:3306 mariadb:11.7-rc
bundle exec rake test:mariadb

# MySQL
docker run -e MYSQL_ALLOW_EMPTY_PASSWORD=1 -e MYSQL_DATABASE=neighbor_test -p 3306:3306 mysql:9
bundle exec rake test:mysql
```
