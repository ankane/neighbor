module Neighbor
  class NormalizedAttribute < ActiveRecord::Type::Value
    delegate :type, :serialize, :deserialize, to: :@cast_type

    def initialize(cast_type:, model:, attribute_name:)
      @cast_type = cast_type
      @model = model
      @attribute_name = attribute_name.to_s
    end

    def cast(value)
      Neighbor::Utils.normalize(@cast_type.cast(value), column_info: @model.columns_hash[@attribute_name])
    end

    private

    def cast_value(...)
      @cast_type.send(:cast_value, ...)
    end
  end
end
