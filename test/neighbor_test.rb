require_relative "test_helper"

class NeighborTest < Minitest::Test
  def setup
    Item.delete_all
  end

  def test_cosine
    create_items(CosineItem)
    result = CosineItem.find(1).nearest_neighbors(distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_cosine_no_normalize
    skip if vector?

    create_items(Item)
    error = assert_raises(Neighbor::Error) do
      Item.find(1).nearest_neighbors(distance: "cosine").first(3)
    end
    assert_equal "Set normalize for cosine distance with cube", error.message
  end

  def test_euclidean
    create_items(Item)
    result = Item.find(1).nearest_neighbors(distance: "euclidean").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 1.7320507764816284], result.map(&:neighbor_distance)
  end

  def test_taxicab
    skip if vector?

    create_items(Item)
    result = Item.find(1).nearest_neighbors(distance: "taxicab").first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_chebyshev
    skip if vector?

    create_items(Item)
    result = Item.find(1).nearest_neighbors(distance: "chebyshev").first(3)
    assert_equal [2, 3], result.map(&:id).sort # same distance
    assert_elements_in_delta [1, 1], result.map(&:neighbor_distance)
  end

  def test_inner_product
    skip unless vector?

    create_items(Item)
    result = Item.find(1).nearest_neighbors(distance: "inner_product").first(3)
    assert_equal [2, 3], result.map(&:id).sort # same distance
    assert_elements_in_delta [6, 4], result.map(&:neighbor_distance)
  end

  def test_relation
    create_items(Item)
    assert_equal [2], Item.find(1).nearest_neighbors(distance: "euclidean").where(id: 2).map(&:id)
  end

  # need to use unscope or count(:all)
  def test_relation_count
    create_items(Item)
    assert_equal 2, Item.find(1).nearest_neighbors(distance: "euclidean").unscope(:select).count
    assert_equal 2, Item.find(2).nearest_neighbors(distance: "euclidean").count(:all)
  end

  def test_empty
    create_items(CosineItem)
    CosineItem.create!(id: 4, neighbor_vector: nil)

    result = CosineItem.find(1).nearest_neighbors(distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)

    assert_empty CosineItem.find(4).nearest_neighbors(distance: "cosine").first(3)
  end

  def test_cosine_zero
    create_items(CosineItem)
    CosineItem.create!(id: 4, neighbor_vector: [0, 0, 0])
    assert_equal [0, 0, 0], CosineItem.last.neighbor_vector

    expected = vector? ? "[0,0,0]" : "(0, 0, 0)"
    assert_equal expected, CosineItem.connection.select_all("SELECT neighbor_vector FROM items WHERE id = 4").first["neighbor_vector"]

    result = CosineItem.find(3).nearest_neighbors(distance: "cosine").to_a.last
    assert_equal 4, result.id
    if vector?
      assert result.neighbor_distance.nan?
    else
      assert_in_delta 0.5, result.neighbor_distance
    end

    result = CosineItem.find(4).nearest_neighbors(distance: "cosine").first(3)
    if vector?
      assert result.map(&:neighbor_distance).all?(&:nan?)
    else
      assert_elements_in_delta [0.5, 0.5, 0.5], result.map(&:neighbor_distance)
    end
  end

  # private, but make sure doesn't update in-place
  def test_cast
    vector = [1, 2, 3]
    Neighbor::Vector.cast(vector, dimensions: 3, normalize: true, column_info: {type: :cube})
    assert_equal [1, 2, 3], vector
  end

  def test_scope
    create_items(CosineItem)
    result = CosineItem.nearest_neighbors([3, 3, 3], distance: "cosine").first(5)
    assert_equal 3, result.size
    assert_equal [1, 2], result.map(&:id).first(2).sort # same distance
    assert_equal 3, result.map(&:id).last
    assert_elements_in_delta [0, 0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_scope_invalid_dimensions
    error = assert_raises(Neighbor::Error) do
      DimensionsItem.nearest_neighbors([3, 3], distance: "euclidean").first(5)
    end
    assert_equal "Expected 3 dimensions, not 2", error.message
  end

  def test_attribute_not_loaded
    create_items(Item)
    assert_raises(ActiveModel::MissingAttributeError) do
      Item.select(:id).find(1).nearest_neighbors(distance: "euclidean")
    end
  end

  def test_large_dimensions
    max_dimensions = vector? ? 1024 : 100
    error = assert_raises(ActiveRecord::StatementInvalid) do
      LargeDimensionsItem.create!(neighbor_vector: (max_dimensions + 1).times.to_a)
    end
    assert_match "cannot have more than #{max_dimensions} dimensions", error.message
  end

  def test_invalid_distance
    error = assert_raises(ArgumentError) do
      Item.nearest_neighbors([1, 2, 3], distance: "bad")
    end
    assert_equal "Invalid distance: bad", error.message
  end

  def test_invalid_dimensions
    error = assert_raises(Neighbor::Error) do
      DimensionsItem.create!(neighbor_vector: [1, 1])
    end
    assert_equal "Expected 3 dimensions, not 2", error.message
  end

  def test_infinite
    error = assert_raises(Neighbor::Error) do
      Item.create!(neighbor_vector: [Float::INFINITY, 0, 0])
    end
    assert_equal "Values must be finite", error.message
  end

  def test_nan
    error = assert_raises(Neighbor::Error) do
      Item.create!(neighbor_vector: [Float::NAN, 0, 0])
    end
    assert_equal "Values must be finite", error.message
  end

  def test_already_defined
    error = assert_raises(Neighbor::Error) do
      Item.has_neighbors
    end
    assert_equal "nearest_neighbors already defined", error.message
  end

  def test_schema
    file = Tempfile.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    file.rewind
    refute_match "Could not dump table", file.read
    load(file.path)
  end

  def create_items(cls)
    vectors = [
      [1, 1, 1],
      [2, 2, 2],
      [1, 1, 2]
    ]
    vectors.each.with_index do |v, i|
      cls.create!(id: i + 1, neighbor_vector: v)
    end
  end
end
