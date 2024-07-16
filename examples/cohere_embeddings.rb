require "json"
require "net/http"
require "active_record"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :documents, force: true do |t|
    t.text :content
    t.bit :embedding, limit: 1024
  end
end

class Document < ActiveRecord::Base
  has_neighbors :embedding
end

# https://docs.cohere.com/reference/embed
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

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings(input, "search_document")

documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: embedding}
end
Document.insert_all!(documents)

query = "forest"
query_embedding = fetch_embeddings([query], "search_query")[0]
pp Document.nearest_neighbors(:embedding, query_embedding, distance: "hamming").first(5).map(&:content)
