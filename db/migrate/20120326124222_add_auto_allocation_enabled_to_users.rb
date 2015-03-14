class AddAutoAllocationEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :auto_allocation_enabled, :boolean, :default => true
  end
end
