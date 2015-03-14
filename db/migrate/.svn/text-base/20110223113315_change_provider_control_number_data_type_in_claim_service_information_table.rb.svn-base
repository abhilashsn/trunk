class ChangeProviderControlNumberDataTypeInClaimServiceInformationTable < ActiveRecord::Migration
  def up
    change_table :claim_service_informations do |t|
      t.change :provider_control_number, :string
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
