class ChangeProviderControlNumberDataTypeInClaimServiceInformations < ActiveRecord::Migration
  def up
    change_column :claim_service_informations, :provider_control_number, :string, :limit => 30
  end

  def down
    change_column :claim_service_informations, :provider_control_number, :integer, :limit => 11
  end
  def connection
    ClaimServiceInformation.connection
  end
end
