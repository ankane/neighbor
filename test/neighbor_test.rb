require_relative "test_helper"

class NeighborTest < Minitest::Test
  def test_relation
    create_items(Item, :embedding)
    assert_equal [2], Item.find(1).nearest_neighbors(:embedding, distance: "euclidean").where(id: 2).map(&:id)
  end

  # need to use unscope or count(:all)
  def test_relation_count
    create_items(Item, :embedding)
    assert_equal 2, Item.find(1).nearest_neighbors(:embedding, distance: "euclidean").unscope(:select).count
    assert_equal 2, Item.find(2).nearest_neighbors(:embedding, distance: "euclidean").count(:all)
  end

  def test_empty
    create_items(CosineItem, :embedding)
    CosineItem.create!(id: 4, embedding: nil)

    result = CosineItem.find(1).nearest_neighbors(:embedding, distance: "cosine").first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)

    assert_empty CosineItem.find(4).nearest_neighbors(:embedding, distance: "cosine").first(3)
  end

  def test_scope
    create_items(CosineItem, :embedding)
    result = CosineItem.nearest_neighbors(:embedding, [3, 3, 3], distance: "cosine").first(5)
    assert_equal 3, result.size
    assert_equal [1, 2], result.map(&:id).first(2).sort # same distance
    assert_equal 3, result.map(&:id).last
    assert_elements_in_delta [0, 0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_scope_invalid_dimensions
    error = assert_raises(Neighbor::Error) do
      DimensionsItem.nearest_neighbors(:embedding, [3, 3], distance: "euclidean").first(5)
    end
    assert_equal "Expected 3 dimensions, not 2", error.message
  end

  def test_scope_select
    create_items(CosineItem, :embedding)
    item = CosineItem.select(:id, :factors).nearest_neighbors(:embedding, [3, 3, 3], distance: "euclidean").first
    assert item.has_attribute?(:id)
    assert item.has_attribute?(:factors)
    refute item.has_attribute?(:embedding)
  end

  def test_default_scope
    create_items(Item, :embedding)
    assert_equal [1, 3, 2], DefaultScopeItem.nearest_neighbors(:embedding, [0, 0, 0], distance: "euclidean").pluck(:id)
    assert_equal [3, 2], DefaultScopeItem.find(1).nearest_neighbors(:embedding, distance: "euclidean").pluck(:id)
  end

  def test_attribute_not_loaded
    create_items(Item, :embedding)
    assert_raises(ActiveModel::MissingAttributeError) do
      Item.select(:id).find(1).nearest_neighbors(:embedding, distance: "euclidean")
    end
  end

  def test_invalid_distance
    error = assert_raises(ArgumentError) do
      Item.nearest_neighbors(:embedding, [1, 2, 3], distance: "bad")
    end
    assert_equal "Invalid distance: bad", error.message
  end

  def test_invalid_dimensions
    error = assert_raises(Neighbor::Error) do
      DimensionsItem.create!(embedding: [1, 1])
    end
    assert_equal "Expected 3 dimensions, not 2", error.message
  end

  def test_infinite
    error = assert_raises(Neighbor::Error) do
      Item.create!(embedding: [Float::INFINITY, 0, 0])
    end
    assert_equal "Values must be finite", error.message
  end

  def test_nan
    error = assert_raises(Neighbor::Error) do
      Item.create!(embedding: [Float::NAN, 0, 0])
    end
    assert_equal "Values must be finite", error.message
  end

  def test_already_defined
    error = assert_raises(Neighbor::Error) do
      Item.has_neighbors :embedding
    end
    assert_equal "has_neighbors already called for :embedding", error.message
  end

  def test_schema
    file = Tempfile.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    file.rewind
    contents = file.read
    refute_match "Could not dump table", contents
    assert_match "t.cube", contents
    assert_match "t.vector", contents
    assert_match "t.halfvec", contents
    assert_match "t.bit", contents
    assert_match "t.sparsevec", contents
    load(file.path)
  end

  def test_no_attribute
    error = assert_raises(ArgumentError) do
      Item.has_neighbors
    end
    assert_equal "has_neighbors requires an attribute name", error.message
  end

  def test_invalid_attribute
    create_items(Item, :embedding)
    error = assert_raises(ArgumentError) do
      Item.find(1).nearest_neighbors(:bad, distance: "euclidean")
    end
    assert_equal "Invalid attribute", error.message
  end

  def test_invalid_attribute_scope
    error = assert_raises(ArgumentError) do
      Item.nearest_neighbors(:bad, [0, 0, 0], distance: "euclidean")
    end
    assert_equal "Invalid attribute", error.message
  end

  def test_neighbor_attributes
    assert_includes Item.neighbor_attributes.keys, :embedding
  end
end
