class ChangeLocationAndEmployeeIdInUsers < ActiveRecord::Migration
  def up
    change_column :users, :employee_id, :string, :limit => 40, :null => false
    change_column :users, :location, :string, :limit => 50, :null => false, :default => 'TVM'
  end

  def down
    change_column :users, :employee_id, :string, :limit => 40, :null => true
    change_column :users, :location, :string, :limit => 50, :null => true, :default => ''
  end
end
