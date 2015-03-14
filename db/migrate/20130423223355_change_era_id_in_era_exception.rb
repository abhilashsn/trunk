class ChangeEraIdInEraException < ActiveRecord::Migration
  def up
    change_column :era_exceptions, :era_id, :integer, :null => false
  end

  def down
    change_column :era_exceptions, :era_id, :integer, :null => true
  end
end
