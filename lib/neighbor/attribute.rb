module Neighbor
  class Attribute < ActiveRecord::Type::Value
    delegate :type, :serialize, :deserialize, :cast, to: :new_cast_type

    def initialize(cast_type:, model:)
      @cast_type = cast_type
      @model = model
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
            Type::SqliteVector.new
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
