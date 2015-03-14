class AlterBatchesForAutoJobAllocation < ActiveRecord::Migration
  def up
    change_table :batches do |t|
      t.boolean :client_wise_auto_allocation_enabled, :default => false
      t.boolean :payer_wise_auto_allocation_enabled, :default => false
      t.integer :priority, :limit => 2, :default => 5
    end
  end

  def down
    remove_column :batches, :client_wise_auto_allocation_enabled
    remove_column :batches, :payer_wise_auto_allocation_enabled
    remove_column :batches, :priority
  end
end
