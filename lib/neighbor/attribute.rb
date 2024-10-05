module Neighbor
  class Attribute < ActiveRecord::Type::Value
    delegate :type, :serialize, :deserialize, :cast, to: :new_cast_type

    def initialize(cast_type:, model:, type:)
      @cast_type = cast_type
      @model = model
      @type = type
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
            case @type.to_s
            when "int8"
              Type::SqliteInt8Vector.new
            when "float32", ""
              Type::SqliteFloat32Vector.new
            else
              raise ArgumentError, "Unsupported type"
            end
          when :mariadb
            Type::MysqlVector.new
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
