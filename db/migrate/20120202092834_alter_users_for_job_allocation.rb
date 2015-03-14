class AlterUsersForJobAllocation < ActiveRecord::Migration
  def up
    remove_column :users, :status
    add_column :users, :login_status, :boolean, :default => false
    add_column :users, :employee_id, :string, :limit => 40
    add_column :users, :eligible_for_payer_wise_job_allocation, :boolean
    add_column :users, :last_job_completed_at, :datetime
    
    add_index(:users, [:login_status, :allocation_status], :name => "by_login_status_and_allocation_status")
    add_index :users, :eligible_for_payer_wise_job_allocation
  end

  def down
    add_column :users, :status, :string
    
    remove_index :users, :name => "by_login_status_and_allocation_status"
    remove_index :users, :eligible_for_payer_wise_job_allocation
    
    remove_column :users, :login_status
    remove_column :users, :employee_id
    remove_column :users, :eligible_for_payer_wise_job_allocation
    remove_column :users, :last_job_completed_at
  end
end
