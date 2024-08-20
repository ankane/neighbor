require "active_record"
require "neighbor"
require "transformers-rb"

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

model = Transformers::SentenceTransformer.new("sentence-transformers/all-MiniLM-L6-v2")

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.encode(input)

documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: embedding}
end
Document.insert_all!(documents)

document = Document.first
pp document.nearest_neighbors(:embedding, distance: "cosine").first(5).map(&:content)
