class AddColumnDrgCodePlanTypeToClaimInformations < ActiveRecord::Migration
  def up
     add_column :claim_informations,:drg_code,:string,:limit=>6
    add_column :claim_informations,:plan_type,:string,:limit=>20
   
  end

  def down
    remove_column :claim_informations,:drg_code
    remove_column :claim_informations,:plan_type
   
  end
  def connection
    ClaimInformation.connection
  end
end
