class ChangeClientIdToFacilityIdForRejectionComment < ActiveRecord::Migration
  def up
    rename_column :rejection_comments, :client_id, :facility_id
  end

  def down
    rename_column :rejection_comments, :facility_id, :client_id
  end
end
