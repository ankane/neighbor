module Neighbor
  class Attribute < ActiveRecord::Type::Value
    delegate :type, :serialize, :deserialize, :cast, to: :@cast_type

    def initialize(cast_type:, model:)
      @cast_type =
        if cast_type.is_a?(ActiveModel::Type::Value)
          case model.connection_db_config.adapter
          when /sqlite/i
            Type::SqliteVector.new
          when /mysql|trilogy/i
            Type::MysqlVector.new
          else
            cast_type
          end
        else
          cast_type
        end
    end

    private

    def cast_value(...)
      @cast_type.send(:cast_value, ...)
    end
  end
end
