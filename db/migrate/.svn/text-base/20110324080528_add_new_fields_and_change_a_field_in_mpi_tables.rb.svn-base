class AddNewFieldsAndChangeAFieldInMpiTables < ActiveRecord::Migration
  def up
    add_column :claim_informations, :additional_claim_informations,:text
    add_column :claim_service_informations, :additional_claim_service_informations,:text
  end

  def down
    remove_column :claim_informations, :additional_claim_informations
    remove_column :claim_service_informations, :additional_claim_service_informations
  end

  def connection
    ClaimInformation.connection
  end
  def connection
    ClaimServiceInformation.connection
  end
end
