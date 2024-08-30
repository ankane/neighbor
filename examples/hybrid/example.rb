require "active_record"
require "informers"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :documents, force: true do |t|
    t.text :content
    t.vector :embedding, limit: 384
  end
end

class Document < ActiveRecord::Base
  has_neighbors :embedding
end

embed = Informers.pipeline("embedding", "Xenova/multi-qa-MiniLM-L6-cos-v1")
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
keyword_results =
  Document
    .where("to_tsvector('english', content) @@ plainto_tsquery('english', ?)", query)
    .order(Arel.sql("ts_rank_cd(to_tsvector('english', content), plainto_tsquery('english', ?)) DESC", query))
    .first(20)

query_embedding = embed.(query)
semantic_results = Document.nearest_neighbors(:embedding, query_embedding, distance: "cosine").first(20)

results = (semantic_results + keyword_results).uniq(&:id)
p rerank.(query, results.map(&:content), top_k: 5).map { |v| results[v[:doc_id]] }.map(&:content)
