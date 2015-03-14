class AddApplyToAllClaimsToJobs < ActiveRecord::Migration
  def change
    add_column :jobs, :apply_to_all_claims, :boolean, :default => 0
  end
end
