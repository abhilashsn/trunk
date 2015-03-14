class AddColumnsToClaimServiceInformations < ActiveRecord::Migration
  def up
    attributes = ["service_id_hash",
      "procedure_code","line_item_charge_amount",
      "service_unit_count","place_of_service_code",
      "identification_code",
      "product_service_id","service_description",
      "remaining_patient_liability_amount",
      "service_units_days","unit_rate",
      "monetary_amount","product_service_id","product_or_service_id_qualifier",
      "facility_code_value"]
    
    if !(attributes - ClaimServiceInformation.column_names).empty?
      execute "ALTER TABLE claim_service_informations
      ADD (service_id_hash VARCHAR(255),
           procedure_code VARCHAR(48),
           line_item_charge_amount DECIMAL(18),
           service_unit_count DECIMAL(15),
           place_of_service_code VARCHAR(2),
           identification_code VARCHAR(80),
           product_or_service_id_qualifier VARCHAR(2),
           product_service_id VARCHAR(48),
           service_description VARCHAR(80),
           remaining_patient_liability_amount DECIMAL(18),
           service_units_days INT(15),
           unit_rate INT(10),
           monetary_amount DECIMAL(18),
           product_service_id_sv301 VARCHAR(48),
           facility_code_value VARCHAR(2)),
      ADD INDEX  (service_id_hash);"
    end
  end

  def down
    execute "ALTER TABLE claim_service_informations
      DROP INDEX service_id_hash,
      DROP COLUMN service_id_hash,
      DROP COLUMN procedure_code,
      DROP COLUMN line_item_charge_amount,
      DROP COLUMN product_or_service_id_qualifier,
      DROP COLUMN service_unit_count,
      DROP COLUMN place_of_service_code,
      DROP COLUMN identification_code,
      DROP COLUMN product_service_id,
      DROP COLUMN service_description,
      DROP COLUMN remaining_patient_liability_amount,
      DROP COLUMN service_units_days,
      DROP COLUMN unit_rate,
      DROP COLUMN monetary_amount,
      DROP COLUMN product_service_id_sv301,
      DROP COLUMN facility_code_value;"
  end

  def connection
    ClaimServiceInformation.connection
  end
end
