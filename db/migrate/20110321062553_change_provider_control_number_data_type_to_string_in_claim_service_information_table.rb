class ChangeProviderControlNumberDataTypeToStringInClaimServiceInformationTable < ActiveRecord::Migration
  def up
   if ClaimServiceInformation.columns_hash['provider_control_number'].type.to_s == "integer"
      change_table :claim_service_informations do |t|
        t.change :provider_control_number, :string
       end
   end
  end

  def down
     change_table :claim_service_informations do |t|
      t.change :provider_control_number, :int
    end
  end
  
  def connection
    ClaimServiceInformation.connection
  end
  
end
