require_relative "test_helper"

class RerankingTest < Minitest::Test
  def setup
    Item.delete_all
  end

  def test_rrf
    create_items(Item, :embedding)
    items = Item.order(:id).to_a
    keyword_results =  Item.where(id: items[2].id).to_a
    semantic_results = [items[2], items[0], items[1]]
    results = Neighbor::Reranking.rrf(keyword_results, semantic_results)

    assert_equal 3, results.size
    assert_equal items[2], results[0][:result]
    assert_in_delta 0.03279, results[0][:score], 0.00001
    assert_equal items[0], results[1][:result]
    assert_in_delta 0.01612, results[1][:score], 0.00001
    assert_equal items[1], results[2][:result]
    assert_in_delta 0.01587, results[2][:score], 0.00001
  end
end
