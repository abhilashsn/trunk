class AddArchiveClaimsInToFacility < ActiveRecord::Migration
  def change
    add_column :facilities, :archive_claims_in, :integer
  end
end
