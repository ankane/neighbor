require_relative "test_helper"

class VectorTest < Minitest::Test
  def test_cosine
    create_items(Item, :embedding)
    result = Item.find(1).nearest_neighbors(:embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(Item, :embedding)
    result = Item.find(1).nearest_neighbors(:embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(Item, :embedding)
    result = Item.find(1).nearest_neighbors(:embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_inner_product
    create_items(Item, :embedding)
    result = Item.find(1).nearest_neighbors(:embedding, distance: "inner_product").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [6, 4], result.map(&:neighbor_distance)
  end

  def test_type
    Item.create!(factors: "[1,2,3]")
    assert_equal [1, 2, 3], Item.last.factors

    Item.create!(factors: [1, 2, 3])
    assert_equal [1, 2, 3], Item.last.factors
  end

  def test_cosine_zero
    create_items(Item, :embedding)
    Item.create!(id: 4, embedding: [0, 0, 0])
    assert_equal [0, 0, 0], Item.last.embedding
    assert_equal "[0,0,0]", Item.connection.select_all("SELECT embedding FROM items WHERE id = 4").first["embedding"]

    result = Item.find(3).nearest_neighbors(:embedding, distance: "cosine").to_a.last
    assert_equal 4, result.id
    assert result.neighbor_distance.nan?

    result = Item.find(4).nearest_neighbors(:embedding, distance: "cosine").first(3)
    assert result.map(&:neighbor_distance).all?(&:nan?)
  end

  def test_large_dimensions
    error = assert_raises(ActiveRecord::StatementInvalid) do
      LargeDimensionsItem.create!(embedding: 16001.times.to_a)
    end
    assert_match "cannot have more than 16000 dimensions", error.message
  end
end
