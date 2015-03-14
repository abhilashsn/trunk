class AddTotalChargesAndTotalExcludedChargesToBatches < ActiveRecord::Migration
  def up
    add_column :batches, :total_charge, :decimal,:precision => 10, :scale => 2
    add_column :batches, :total_excluded_charge, :decimal,:precision => 10, :scale => 2
  end

  def down
    remove_column :batches, :total_charge
    remove_column :batches, :total_excluded_charge
  end
end
