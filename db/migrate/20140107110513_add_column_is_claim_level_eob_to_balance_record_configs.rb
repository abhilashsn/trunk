class AddColumnIsClaimLevelEobToBalanceRecordConfigs < ActiveRecord::Migration
  def change
    add_column :balance_record_configs, :is_claim_level_eob, :boolean, :default => 0
  end
end
