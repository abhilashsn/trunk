class ChangeDefaultValueOfIsDeletedInUsers < ActiveRecord::Migration
  def up
    change_column :users, :is_deleted,:boolean, :default => 0
  end

  def down
    change_column :users, :is_deleted,:boolean
  end
end
