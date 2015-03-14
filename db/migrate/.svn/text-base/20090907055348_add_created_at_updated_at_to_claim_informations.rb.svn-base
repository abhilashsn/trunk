class AddCreatedAtUpdatedAtToClaimInformations < ActiveRecord::Migration
  def up
    add_column :claim_informations, :created_at, :datetime
    add_column :claim_informations, :updated_at, :datetime
  end

  def down
     remove_column :claim_informations, :created_at
     remove_column :claim_informations, :updated_at
  end
  def connection
    ClaimInformation.connection
  end
end
