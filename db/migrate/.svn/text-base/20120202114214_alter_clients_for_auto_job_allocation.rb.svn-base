class AlterClientsForAutoJobAllocation < ActiveRecord::Migration
  def up
    change_table :clients do |t|
      t.integer :internal_tat
      t.integer :max_eobs_per_job, :default => 15
      t.integer :max_jobs_per_user, :default => 5
    end
  end

  def down
    remove_column :clients, :internal_tat
    remove_column :clients, :max_eobs_per_job, :default => 15
    remove_column :clients, :max_jobs_per_user, :default => 5
  end

end
