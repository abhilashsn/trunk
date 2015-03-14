class AddChangedParamToClaimInformations < ActiveRecord::Migration
  def change
    add_column :claim_informations, :changed_param, :string
  end

  def connection
    ClaimInformation.connection
  end
  
end
