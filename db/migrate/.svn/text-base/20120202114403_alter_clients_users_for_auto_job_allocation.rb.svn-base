class AlterClientsUsersForAutoJobAllocation < ActiveRecord::Migration
  def up
    add_column :clients_users, :eobs_processed, :integer
    add_column :clients_users, :eligible_for_auto_allocation, :boolean, :default => false

    add_index :clients_users, :eligible_for_auto_allocation
  end

  def down
   remove_index :clients_users, :eligible_for_auto_allocation
   remove_column :clients_users, :eobs_processed    
   remove_column :clients_users, :eligible_for_auto_allocation
  end
  
end
