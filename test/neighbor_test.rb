require_relative "test_helper"

class NeighborTest < Minitest::Test
  def setup
    Item.delete_all
  end

  def test_cosine
    create_items(Item)
    result = Item.find(1).nearest_neighbors.first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_euclidean
    create_items(EuclideanItem)
    result = EuclideanItem.find(1).nearest_neighbors.first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 1.7320507764816284], result.map(&:neighbor_distance)
  end

  def test_taxicab
    create_items(TaxicabItem)
    result = TaxicabItem.find(1).nearest_neighbors.first(3)
    assert_equal [3, 2], result.map(&:id)
    assert_elements_in_delta [1, 3], result.map(&:neighbor_distance)
  end

  def test_chebyshev
    create_items(ChebyshevItem)
    result = ChebyshevItem.find(1).nearest_neighbors.first(3)
    assert_equal [2, 3], result.map(&:id).sort # same distance
    assert_elements_in_delta [1, 1], result.map(&:neighbor_distance)
  end

  def test_relation
    create_items(Item)
    assert_equal [2], Item.find(1).nearest_neighbors.where(id: 2).map(&:id)
  end

  # need to use unscope or count(:all)
  def test_relation_count
    create_items(Item)
    assert_equal 2, Item.find(1).nearest_neighbors.unscope(:select).count
    assert_equal 2, Item.find(2).nearest_neighbors.count(:all)
  end

  def test_empty
    create_items(Item)
    Item.create!(id: 4, neighbor_vector: nil)

    result = Item.find(1).nearest_neighbors.first(3)
    assert_equal [2, 3], result.map(&:id)
    assert_elements_in_delta [0, 0.05719095841050148], result.map(&:neighbor_distance)

    assert_empty Item.find(4).nearest_neighbors.first(3)
  end

  def test_scope
    create_items(Item)
    result = Item.nearest_neighbors([3, 3, 3]).first(5)
    assert_equal 3, result.size
    assert_equal [1, 2], result.map(&:id).first(2).sort # same distance
    assert_equal 3, result.map(&:id).last
    assert_elements_in_delta [0, 0, 0.05719095841050148], result.map(&:neighbor_distance)
  end

  def test_attribute_not_loaded
    create_items(Item)
    assert_raises(ActiveModel::MissingAttributeError) do
      Item.select(:id).find(1).nearest_neighbors
    end
  end

  def test_large_dimensions
    error = assert_raises(ActiveRecord::StatementInvalid) do
      LargeDimensionsItem.create!(neighbor_vector: 101.times.to_a)
    end
    assert_match "A cube cannot have more than 100 dimensions", error.message
  end

  def test_invalid_distance
    error = assert_raises(ArgumentError) do
      Item.has_neighbors(dimensions: 3, distance: "bad")
    end
    assert_equal "Invalid distance: bad", error.message
  end

  def test_invalid_dimensions
    error = assert_raises(Neighbor::Error) do
      Item.create!(neighbor_vector: [1, 1])
    end
    assert_equal "Expected 3 dimensions, not 2", error.message
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
