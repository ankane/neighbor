require_relative "test_helper"

class HalfvecTest < PostgresTest
  def test_cosine
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, Math.sqrt(3)], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_inner_product
    create_items(Item, :half_embedding)
    result = Item.find(1).nearest_neighbors(:half_embedding, distance: "inner_product").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [6, 4], result.map(&:neighbor_distance)
  end

  def test_index_scan
    assert_index_scan Item.nearest_neighbors(:half_embedding, [0, 0, 0], distance: "cosine")
  end

  def test_type
    Item.create!(half_factors: "[1,2,3]")
    assert_equal [1, 2, 3], Item.last.half_factors

    Item.create!(half_factors: [1, 2, 3])
    assert_equal [1, 2, 3], Item.last.half_factors
  end

  def test_invalid_dimensions
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(half_embedding: [1, 1])
    end
    assert_equal "Validation failed: Half embedding must have 3 dimensions", error.message
  end

  def test_infinite
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(half_embedding: [Float::INFINITY, 0, 0])
    end
    assert_equal "Validation failed: Half embedding must have finite values", error.message
  end

  def test_nan
    error = assert_raises(ActiveRecord::RecordInvalid) do
      Item.create!(half_embedding: [Float::NAN, 0, 0])
    end
    assert_equal "Validation failed: Half embedding must have finite values", error.message
  end

  def test_array
    item = Item.create!(half_embeddings: [[1, 2, 3], [4, 5, 6]])
    assert_equal [[1, 2, 3], [4, 5, 6]], item.half_embeddings
    assert_equal [[1, 2, 3], [4, 5, 6]], Item.last.half_embeddings
  end

  def test_array_2d
    item = Item.create!(half_embeddings: [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]])
    assert_equal [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]], item.half_embeddings
    assert_equal [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [10, 11, 12]]], Item.last.half_embeddings
  end
end
