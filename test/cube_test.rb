require_relative "test_helper"

class CubeTest < Minitest::Test
  def test_cosine
    create_items(CosineItem, :cube_embedding)
    result = CosineItem.find(1).nearest_neighbors(:cube_embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_cosine_no_normalize
    create_items(Item, :cube_embedding)
    error = assert_raises(Neighbor::Error) do
      Item.find(1).nearest_neighbors(:cube_embedding, distance: "cosine").first(3)
    end
    assert_equal "Set normalize for cosine distance with cube", error.message
  end

  def test_euclidean
    create_items(Item, :cube_embedding)
    result = Item.find(1).nearest_neighbors(:cube_embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(Item, :cube_embedding)
    result = Item.find(1).nearest_neighbors(:cube_embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_chebyshev
    create_items(Item, :cube_embedding)
    result = Item.find(1).nearest_neighbors(:cube_embedding, distance: "chebyshev").first(3)
    assert_equal [2, 3], result.map(&:id).sort # same distance
    assert_elements_in_delta [1, 1], result.map(&:neighbor_distance)
  end

  def test_type
    Item.create!(cube_factors: "(1,2,3)")
    assert_equal [1, 2, 3], Item.last.cube_factors

    Item.create!(cube_factors: [1, 2, 3])
    assert_equal [1, 2, 3], Item.last.cube_factors

    Item.create!(cube_factors: 1)
    assert_equal [1], Item.last.cube_factors

    Item.create!(cube_factors: [[1, 2, 3], [4, 5, 6]])
    assert_equal [[1, 2, 3], [4, 5, 6]], Item.last.cube_factors
  end

  # private, but make sure doesn't update in-place
  def test_cast
    vector = [1, 2, 3]
    Neighbor::Vector.cast(vector, dimensions: 3, normalize: true, column_info: {type: :cube})
    assert_equal [1, 2, 3], vector
  end

  def test_cosine_zero
    create_items(CosineItem, :cube_embedding)
    CosineItem.create!(id: 4, cube_embedding: [0, 0, 0])
    assert_equal [0, 0, 0], CosineItem.last.cube_embedding
    assert_equal "(0, 0, 0)", CosineItem.connection.select_all("SELECT cube_embedding FROM items WHERE id = 4").first["cube_embedding"]

    result = CosineItem.find(3).nearest_neighbors(:cube_embedding, distance: "cosine").to_a.last
    assert_equal 4, result.id
    assert_in_delta 0.5, result.neighbor_distance

    result = CosineItem.find(4).nearest_neighbors(:cube_embedding, distance: "cosine").first(3)
    assert_elements_in_delta [0.5, 0.5, 0.5], result.map(&:neighbor_distance)
  end

  def test_large_dimensions
    error = assert_raises(ActiveRecord::StatementInvalid) do
      LargeDimensionsItem.create!(cube_embedding: 101.times.to_a)
    end
    assert_match "cannot have more than 100 dimensions", error.message
  end

  def test_invalid_dimensions
    error = assert_raises(Neighbor::Error) do
      DimensionsItem.create!(cube_embedding: [1, 1])
    end
    assert_equal "Expected 3 dimensions, not 2", error.message
  end
end
