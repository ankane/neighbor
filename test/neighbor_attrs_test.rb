require_relative "test_helper"

class NeighborAttrsTest < Minitest::Test
  def setup
    Item.delete_all
  end

  def test_attribute_order_desc
    4.times { |i| DimensionsItem.create!(embedding: [-i, 3, i]) }

    result_scores = DimensionsItem.nearest_neighbors(
      :embedding, [3, 3, 3],
      distance: "euclidean",
      order: { neighbor_distance: :desc }
    ).map(&:neighbor_distance)

    assert_equal result_scores, result_scores.sort.reverse 
  end

  def test_attribute_order_asc
    4.times { |i| DimensionsItem.create!(embedding: [-i, 3, i]) }

    result_scores = DimensionsItem.nearest_neighbors(
      :embedding, [3, 3, 3],
      distance: "euclidean",
      order: { neighbor_distance: :desc }
    ).map(&:neighbor_distance)

    assert_equal result_scores, result_scores.sort.reverse 
  end

  def test_attribute_limit
    3.times { |i| DimensionsItem.create!(embedding: [-i, 3, i]) }

    results = DimensionsItem.nearest_neighbors(
      :embedding, [3, 3, 3],
      distance: "euclidean",
      limit: 1
    )

    assert_equal 1, results.length 
  end

  def test_attribute_threshold_lt
    # Close neighbor
    DimensionsItem.create!(embedding: [3, 3, 3])
    # Far away neighbor
    DimensionsItem.create!(embedding: [3, 3, 10])

    results = DimensionsItem.nearest_neighbors(
      :embedding, [3, 3, 3],
      distance: "euclidean",
      threshold: { lt: 1 }
    )

    assert_equal 1, results.length 
  end

  class MultipleAttibuteTests < Minitest::Test
    def setup
      5.times { |i| DimensionsItem.create!(embedding: [-i, 5, i]) }

      # Run query using all options
      @results = DimensionsItem.nearest_neighbors(
        :embedding, [-3, 5, 3],
        distance: "euclidean",
        order: { neighbor_distance: :desc },
        threshold: { lte: 3 },
        limit: 2
      )
    end

    def test_multiple_attributes_limit
      assert_equal 2, @results.length
    end

    def test_multiple_attributes_order
      assert_equal @results.map(&:neighbor_distance), @results.map(&:neighbor_distance).sort.reverse
    end

    def test_multiple_attributes_threshold
      assert @results.all? { |result| result.neighbor_distance <= 3 }
    end
  end
end