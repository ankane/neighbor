module Neighbor
  class Attribute < ActiveRecord::Type::Value
    delegate :type, :serialize, :deserialize, :cast, to: :new_cast_type

    def initialize(cast_type:, model:, type:, attribute_name:)
      @cast_type = cast_type
      @model = model
      @type = type
      @attribute_name = attribute_name
    end

    private

    def cast_value(...)
      new_cast_type.send(:cast_value, ...)
    end

    def new_cast_type
      @new_cast_type ||= begin
        if @cast_type.is_a?(ActiveModel::Type::Value)
          case Utils.adapter(@model)
          when :sqlite
            case @type&.to_sym
            when :int8
              Type::SqliteInt8Vector.new
            when :bit
              @cast_type
            when :float32, nil
              Type::SqliteVector.new
            else
              raise ArgumentError, "Unsupported type"
            end
          when :mariadb
            if @model.columns_hash[@attribute_name.to_s]&.type == :integer
              @cast_type
            else
              Type::MysqlVector.new
            end
          else
            @cast_type
          end
        else
          @cast_type
        end
      end
    end
  end
end
