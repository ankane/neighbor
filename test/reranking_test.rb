require_relative "test_helper"

class RerankingTest < Minitest::Test
  def test_rrf
    keyword_results =  ["C"]
    semantic_results = ["C", "A", "B"]
    results = Neighbor::Reranking.rrf(keyword_results, semantic_results)
    assert_equal ["C", "A", "B"], results.map { |v| v[:result] }
    assert_elements_in_delta [0.03279, 0.01612, 0.01587], results.map { |v| v[:score] }
  end

  def test_rrf_k
    results = Neighbor::Reranking.rrf(["A", "B", "C"], k: 0)
    assert_equal ["A", "B", "C"], results.map { |v| v[:result] }
    assert_elements_in_delta [1, 0.5, 1 / 3.0], results.map { |v| v[:score] }
  end
end
