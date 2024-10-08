require "bundler/setup"
require "active_record"
require "informers"
require "neighbor"

ActiveRecord.async_query_executor = :global_thread_pool
ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :documents, force: true do |t|
    t.text :content
    t.vector :embedding, limit: 768
  end

  # optional: add indexes
  add_index :documents, "to_tsvector('english', coalesce(content, ''))", using: :gin
  add_index :documents, :embedding, using: :hnsw, opclass: :vector_cosine_ops
end

class Document < ActiveRecord::Base
  has_neighbors :embedding

  scope :search, ->(query, columns: [:content], language: "english") {
    expression = columns.map { |v| "coalesce(#{connection.quote_column_name(v)}, '')" }.join(" || ' ' || ")
    where("to_tsvector(?, #{expression}) @@ plainto_tsquery(?, ?)", language, language, query)
      .order(Arel.sql("ts_rank_cd(to_tsvector(?, #{expression}), plainto_tsquery(?, ?)) DESC", language, language, query))
  }
end

Document.create!(content: "The dog is barking")
Document.create!(content: "The cat is purring")
Document.create!(content: "The bear is growling")

embed = Informers.pipeline("embedding", "Snowflake/snowflake-arctic-embed-m-v1.5")
embed_options = {model_output: "sentence_embedding", pooling: "none"} # specific to embedding model

Document.find_each do |document|
  embedding = embed.(document.content, **embed_options)
  document.update!(embedding: embedding)
end

query = "growling bear"
keyword_results = Document.search(query).limit(20).load_async

# the query prefix is specific to the embedding model (https://huggingface.co/Snowflake/snowflake-arctic-embed-m-v1.5)
query_prefix = "Represent this sentence for searching relevant passages: "
query_embedding = embed.(query_prefix + query, **embed_options)
semantic_results = Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(20).load_async

# to combine the results, use Reciprocal Rank Fusion (RRF)
p Neighbor::Reranking.rrf(keyword_results, semantic_results).first(5).map { |v| v[:result].content }

# or a reranking model
rerank = Informers.pipeline("reranking", "mixedbread-ai/mxbai-rerank-xsmall-v1")
results = (keyword_results + semantic_results).uniq
p rerank.(query, results.map(&:content)).first(5).map { |v| results[v[:doc_id]] }.map(&:content)
