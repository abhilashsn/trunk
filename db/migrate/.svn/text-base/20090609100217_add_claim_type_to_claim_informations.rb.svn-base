class AddClaimTypeToClaimInformations < ActiveRecord::Migration
  def up
     add_column :claim_informations, :claim_type,  :string
  end

  def down
     remove_column :claim_informations, :claim_type
  end
  def connection
    ClaimInformation.connection
  end
end
