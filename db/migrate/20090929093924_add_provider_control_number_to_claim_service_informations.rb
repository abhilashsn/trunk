class AddProviderControlNumberToClaimServiceInformations < ActiveRecord::Migration
  def up
    begin
      add_column :claim_service_informations, :provider_control_number,  :integer
    rescue 
    end
  end

  def down
    remove_column :claim_service_informations, :provider_control_number
  end
  def connection
    ClaimServiceInformation.connection
  end
end
