class AddEligibleForAutoAllocationAndEobProcessedToFacilitiesUsers < ActiveRecord::Migration
  def change
    add_column :facilities_users, :eligible_for_auto_allocation, :boolean, :default => 0
    add_column :facilities_users, :eobs_processed, :integer, :default => 0
  end
end
