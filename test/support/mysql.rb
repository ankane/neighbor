class MysqlRecord < ActiveRecord::Base
  self.abstract_class = true

  establish_connection adapter: "mysql2", database: "neighbor_test"
end

MysqlRecord.connection.instance_eval do
  create_table :mysql_items, force: true do |t|
    t.vector :embedding, limit: 3
  end
end

class MysqlItem < MysqlRecord
end
