# good resources
# https://opensearch.org/blog/improving-document-retrieval-with-sparse-semantic-encoders/
# https://huggingface.co/opensearch-project/opensearch-neural-sparse-encoding-v1

require "bundler/setup"
require "active_record"
require "neighbor"
require "transformers-rb"

ActiveRecord::Base.establish_connection adapter: "postgresql", database: "neighbor_test"
ActiveRecord::Schema.verbose = false
ActiveRecord::Schema.define do
  enable_extension "vector"

  create_table :documents, force: true do |t|
    t.text :content
    t.sparsevec :embedding, limit: 30522
  end
end

class Document < ActiveRecord::Base
  has_neighbors :embedding
end

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

input = [
  "The dog is barking",
  "The cat is purring",
  "The bear is growling"
]
embeddings = model.embed(input)

documents = []
input.zip(embeddings) do |content, embedding|
  documents << {content: content, embedding: Neighbor::SparseVector.new(embedding)}
end
Document.insert_all!(documents)

query = "puppy"
query_embedding = model.embed([query])[0]
pp Document.nearest_neighbors(:embedding, Neighbor::SparseVector.new(query_embedding), distance: "inner_product").first(5).map(&:content)
