class RemovedUnusedFieldsFromClaimServiceInformations < ActiveRecord::Migration
  def up
    remove_column :claim_service_informations, :facility_code_value  if column_exists? :claim_service_informations, :facility_code_value
    remove_column :claim_service_informations, :product_service_id_sv301  if column_exists? :claim_service_informations, :product_service_id_sv301
    remove_column :claim_service_informations, :service_units_days  if column_exists? :claim_service_informations, :service_units_days
    remove_column :claim_service_informations, :unit_rate  if column_exists? :claim_service_informations, :unit_rate
  end

  def down
    add_column :claim_service_informations, :facility_code_value  unless column_exists? :claim_service_informations, :facility_code_value
    add_column :claim_service_informations, :product_service_id_sv301  unless column_exists? :claim_service_informations, :product_service_id_sv301
    add_column :claim_service_informations, :service_units_days  unless column_exists? :claim_service_informations, :service_units_days
    add_column :claim_service_informations, :unit_rate  unless column_exists? :claim_service_informations, :unit_rate
  end

  def connection
    ClaimInformation.connection
  end
  
end
