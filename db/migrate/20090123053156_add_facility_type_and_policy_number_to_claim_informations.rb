class AddFacilityTypeAndPolicyNumberToClaimInformations < ActiveRecord::Migration
  def up
    add_column :claim_informations,:facility_type_code, :string
    add_column :claim_informations,:policy_number, :string
  end

  def down
     remove_column :claim_informations,:facility_type_code
     remove_column :claim_informations,:policy_number
  end
  def connection
    ClaimInformation.connection
  end
end
