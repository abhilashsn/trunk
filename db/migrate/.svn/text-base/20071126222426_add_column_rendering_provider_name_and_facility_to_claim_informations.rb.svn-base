class AddColumnRenderingProviderNameAndFacilityToClaimInformations < ActiveRecord::Migration
  def up
    add_column :claim_informations, :provider_ein,:string,:limit =>15
    add_column :claim_informations, :facility_id,:integer
    add_column :claim_informations, :provider_last_name,:string,:limit =>28
    add_column :claim_informations, :provider_suffix,:string,:limit =>20
    add_column :claim_informations, :provider_first_name,:string,:limit =>28
    add_column :claim_informations, :provider_middle_initial,:string,:limit =>28
      
  end

  def down
    remove_column :claim_informations, :provider_ein
    remove_column :claim_informations, :facility_id
    remove_column :claim_informations, :provider_last_name
    remove_column :claim_informations, :provider_suffix
    remove_column :claim_informations, :provider_first_name
    remove_column :claim_informations, :provider_middle_initial
   
  end
  def connection
    ClaimInformation.connection
  end
end
