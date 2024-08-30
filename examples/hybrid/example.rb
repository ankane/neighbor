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
    t.vector :embedding, limit: 1024
  end
end

class Document < ActiveRecord::Base
  has_neighbors :embedding

  scope :keyword_search, ->(query) {
    where("to_tsvector(content) @@ plainto_tsquery(?)", query)
      .order(Arel.sql("ts_rank_cd(to_tsvector(content), plainto_tsquery(?)) DESC", query))
  }
end

embed = Informers.pipeline("embedding", "mixedbread-ai/mxbai-embed-large-v1")
rerank = Informers.pipeline("reranking", "mixedbread-ai/mxbai-rerank-base-v1")

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = embed.(input)

documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: embedding}
end
Document.insert_all!(documents)

query = "growling bear"
keyword_results = Document.keyword_search(query).limit(20).load_async

# the query prefix is specific to the embedding model (https://huggingface.co/mixedbread-ai/mxbai-embed-large-v1)
query_prefix = "Represent this sentence for searching relevant passages: "
query_embedding = embed.(query_prefix + query)
semantic_results = Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").limit(20).load_async

results = (keyword_results + semantic_results).uniq(&:id)
p rerank.(query, results.map(&:content), top_k: 5).map { |v| results[v[:doc_id]] }.map(&:content)
