require "json"
require "net/http"
require "active_record"
require "neighbor"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :articles, force: true do |t|
    t.text :content
    t.vector :embedding, limit: 1536
  end
end

class Article < ActiveRecord::Base
  has_neighbors :embedding
end

# https://platform.openai.com/docs/guides/embeddings/how-to-get-embeddings
# input can be an array with 2048 elements
def fetch_embeddings(input)
  url = "https://api.openai.com/v1/embeddings"
  headers = {
    "Authorization" => "Bearer #{ENV.fetch("OPENAI_API_KEY")}",
    "Content-Type" => "application/json"
  }
  data = {
    input: input,
    model: "text-embedding-ada-002"
  }

  response = Net::HTTP.post(URI(url), data.to_json, headers)
  JSON.parse(response.body)["data"].map { |v| v["embedding"] }
end

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = fetch_embeddings(input)

articles = []
input.zip(embeddings) do |content, embedding|
  articles << {content: content, embedding: embedding}
end
Article.insert_all!(articles) # use create! for Active Record < 6

article = Article.first
# use inner product for performance since embeddings are normalized
pp article.nearest_neighbors(:embedding, distance: "inner_product").first(5).map(&:content)
